# frozen_string_literal: true
# rubocop: disable CodeReuse/ActiveRecord

module EESpecificCheck
  WHITELIST = [
    'CHANGELOG-EE.md',
    'scripts/**/*',
    'vendor/assets/javascripts/jasmine-jquery.js',
    '.gitlab-ci.yml',
    '.gitlab/ci/rails.gitlab-ci.yml',
    'db/schema.rb',
    'locale/gitlab.pot'
  ].freeze

  CompareBase = Struct.new(:ce_base, :ee_base, :ce_head, :ee_head)
  GitStatus = Struct.new(:porcelain, :head)

  module_function

  def git_version
    say run_git_command('--version')
  end

  def say(message)
    warn "\n#{message}", "\n" # puts would eat trailing newline
  end

  def find_compare_base
    git_clean

    ce_fetch_head = fetch_remote_ce_branch
    ee_fetch_head = head_commit_sha
    ce_fetch_base = find_merge_base('canonical-ce/master', ce_fetch_head)
    ee_fetch_base = find_merge_base('canonical-ee/master', 'HEAD')
    ce_merge_base = find_merge_base(ce_fetch_head, ee_fetch_head)

    ce_updated_head =
      find_ce_compare_head(ce_fetch_head, ce_fetch_base, ce_merge_base)

    CompareBase.new(
      ce_merge_base, ee_fetch_base, ce_updated_head, ee_fetch_head)
  end

  def setup_canonical_remotes
    run_git_command(
      "remote add canonical-ee https://gitlab.com/gitlab-org/gitlab-ee.git",
      "remote add canonical-ce https://gitlab.com/gitlab-org/gitlab-ce.git",
      "fetch canonical-ee master --quiet --depth=9999",
      "fetch canonical-ce master --quiet --depth=9999")
  end

  def fetch_remote_ce_branch
    setup_canonical_remotes

    remote_to_fetch, branch_to_fetch = find_remote_ce_branch

    run_git_command("fetch #{remote_to_fetch} #{branch_to_fetch} --quiet --depth=9999")

    "#{remote_to_fetch}/#{branch_to_fetch}"
  end

  def find_merge_base(left, right)
    merge_base = run_git_command("merge-base #{left} #{right}")

    return merge_base unless merge_base.empty?

    say <<~MESSAGE
      💥 Unfortunately we cannot find the merge-base for #{left} and #{right},
      💥 and we'll try to fix that in:
          https://gitlab.com/gitlab-org/gitlab-ee/issues/9120

      💥 Before that, please run this job locally as a workaround:

          ./scripts/ee-specific-lines-check

      💥 And paste the result as a discussion to show it to the maintainer.
      💥 If you have any questions, please ping @godfat to investigate and
      💥 clarify.
    MESSAGE

    exit(253)
  end

  def find_ce_compare_head(ce_fetch_head, ce_fetch_base, ce_merge_base)
    if git_ancestor?(ce_merge_base, ce_fetch_base)
      say("CE is ahead of EE, finding backward CE head")
      find_backward_ce_head(ce_fetch_head, ce_fetch_base, ce_merge_base)
    else
      say("CE is behind of EE, finding forward CE head")
      find_forward_ce_head(ce_merge_base, ce_fetch_head)
    end
  end

  def git_ancestor?(ancestor, descendant)
    run_git_command(
      "merge-base --is-ancestor #{ancestor} #{descendant} && echo y") == 'y'
  end

  def find_backward_ce_head(ce_fetch_head, ce_fetch_base, ce_merge_base)
    if ce_fetch_head.start_with?('canonical-ce') # No specific CE branch
      say("No CE branch found, using merge base directly")
      ce_merge_base
    elsif ce_fetch_base == ce_merge_base # Up-to-date, no rebase needed
      say("EE is up-to-date with CE, using #{ce_fetch_head} directly")
      ce_fetch_head
    else
      say("Performing rebase to remove commits in CE haven't merged into EE")
      checkout_and_rebase(ce_merge_base, ce_fetch_base, ce_fetch_head)
    end
  end

  def find_forward_ce_head(ce_merge_base, ce_fetch_head)
    say("Performing merge with CE master for CE branch #{ce_fetch_head}")
    with_detached_head(ce_fetch_head) do
      run_git_command("merge #{ce_merge_base} -s recursive -X patience -m 'ee-specific-auto-merge'")

      status = git_status

      if status.porcelain == ''
        status.head
      else
        diff = run_git_command("diff")
        run_git_command("merge --abort")

        say <<~MESSAGE
          💥 Git status not clean! This means there's a conflict in
          💥 #{ce_fetch_head} with canonical-ce/master. Please resolve
          💥 the conflict from CE master and retry this job.

          ⚠️ Git diff:

          #{diff}
        MESSAGE

        exit(254)
      end
    end
  end

  # We rebase onto the commit which is the latest commit presented in both
  # CE and EE, i.e. ce_merge_base, cutting off commits aren't merged into
  # EE yet. Here's an example:
  #
  # * o: Relevant commits
  # * x: Irrelevant commits
  # * !: Commits we want to cut off from CE branch
  #
  #                ^-> o CE branch (ce_fetch_head)
  #               / (ce_fetch_base)
  #     o -> o -> ! -> x CE master
  #          v (ce_merge_base)
  #     o -> o -> o -> x EE master
  #               \ (ee_fetch_base)
  #                v-> o EE branch
  #
  # We want to rebase above into this: (we only change the connection)
  #
  #            -> - -> o CE branch (ce_fetch_head)
  #           / (ce_fetch_base)
  #     o -> o -> ! -> x CE master
  #          v (ce_merge_base)
  #     o -> o -> o -> x EE master
  #               \ (ee_fetch_base)
  #                v-> o EE branch
  #
  # Therefore we rebase onto ce_merge_base, which is based off CE master,
  # for the CE branch (ce_fetch_head), effective remove the commit marked
  # as ! in the graph for CE branch. We need to remove it because it's not
  # merged into EE yet, therefore won't be available in the EE branch.
  #
  # After rebase is done, then we could compare against
  # ce_merge_base..ee_fetch_base along with ce_fetch_head..HEAD (EE branch)
  # where ce_merge_base..ee_fetch_base is the update-to-date
  # CE/EE difference and ce_fetch_head..HEAD is the changes we made in
  # CE and EE branches.
  def checkout_and_rebase(new_base, old_base, target_head)
    with_detached_head(target_head) do
      run_git_command("rebase --onto #{new_base} #{old_base} #{target_head}")

      status = git_status

      if status.porcelain == ''
        status.head
      else
        diff = run_git_command("diff")
        run_git_command("rebase --abort")

        say <<~MESSAGE
          💥 Git status is not clean! This means the CE branch has or had a
          💥 conflict with CE master, and we cannot resolve this in an
          💥 automatic way.
          💥
          💥 Please rebase #{target_head} with CE master.
          💥
          💥 For more details, please read:
          💥   https://gitlab.com/gitlab-org/gitlab-ee/issues/6038#note_86862115
          💥
          💥 Git diff:

          #{diff}
        MESSAGE

        exit(255)
      end
    end
  end

  def with_detached_head(target_head)
    # So that we could switch back. CI sometimes doesn't have the branch,
    # so we don't use current_branch here
    head = current_head

    # Use detached HEAD so that we don't update HEAD
    run_git_command("checkout -f #{target_head}")
    git_clean

    yield
  ensure # ensure would still run if we call exit, don't worry
    # Make sure to switch back
    run_git_command("checkout -f #{head}")
    git_clean
  end

  def head_commit_sha
    run_git_command("rev-parse HEAD")
  end

  def git_status
    GitStatus.new(
      run_git_command("status --porcelain"),
      head_commit_sha
    )
  end

  def git_clean
    # We're still seeing errors not ignoring knapsack/ and rspec_flaky/
    # Instead of waiting that populate over all the branches, we could
    # just remove untracked files anyway, only on CI of course in case
    # we're wiping people's data!
    # See https://gitlab.com/gitlab-org/gitlab-ee/issues/5912
    # Also see https://gitlab.com/gitlab-org/gitlab-ee/-/jobs/68194333
    run_git_command('clean -fd') if ENV['CI']
  end

  def remove_remotes
    run_git_command(
      "remote remove canonical-ee",
      "remote remove canonical-ce",
      "remote remove target-ce")
  end

  def updated_diff_numstat(from, to)
    scan_diff_numstat(
      run_git_command("diff #{from}..#{to} --numstat -- . ':!ee' ':!qa/qa/ee' ':!qa/qa/ee.rb' ':!qa/qa/specs/features/ee'"))
  end

  def find_remote_ce_branch
    branch_to_fetch = matching_ce_refs.first

    if branch_to_fetch
      say "💪 We found the branch '#{branch_to_fetch}' in the #{ce_repo_url} repository. We will fetch it."

      run_git_command("remote add target-ce #{ce_repo_url}")

      ['target-ce', branch_to_fetch]
    else
      say <<~MESSAGE
        ⚠️ We did not find a branch that would match the current '#{current_branch}' branch in the #{ce_repo_url} repository. We will fetch 'master' instead.
        ℹ️ If you have a CE branch for the current branch, make sure that its name includes '#{minimal_ce_branch_name}'.
      MESSAGE

      %w[canonical-ce master]
    end
  end

  def ce_repo_url
    @ce_repo_url ||=
      begin
        repo_url = ENV.fetch('CI_REPOSITORY_URL', 'https://gitlab.com/gitlab-org/gitlab-ce.git')
        # This workaround can be removed once we rename the dev CE project
        # https://gitlab.com/gitlab-org/gitlab-ce/issues/59107
        project_name = repo_url =~ /dev\.gitlab\.org/ ? 'gitlabhq' : 'gitlab-ce'

        repo_url.sub('gitlab-ee', project_name)
      end
  end

  def current_head
    @current_head ||= ENV.fetch('CI_COMMIT_SHA', current_branch)
  end

  def current_branch
    @current_branch ||= ENV.fetch('CI_COMMIT_REF_NAME', `git rev-parse --abbrev-ref HEAD`).strip
  end

  def minimal_ce_branch_name
    @minimal_ce_branch_name ||= current_branch.sub(/(\Aee\-|\-ee\z)/, '')
  end

  def matching_ce_refs
    @matching_ce_refs ||=
      run_git_command("ls-remote #{ce_repo_url} \"*#{minimal_ce_branch_name}*\"")
        .scan(%r{(?<=refs/heads/|refs/tags/).+})
        .select { |branch| branch.match?(/\b#{minimal_ce_branch_name}\b/i) }
        .sort_by(&:size)
  end

  def scan_diff_numstat(numstat)
    numstat.scan(/(\d+)\s+(\d+)\s+(.+)/)
      .each_with_object(Hash.new(0)) do |(added, deleted, file), result|
        result[file] = added.to_i + deleted.to_i
      end
  end

  def run_git_command(*commands)
    cmds = commands.map { |cmd| "git #{cmd}" }

    output = run_command(*cmds)

    if commands.size == 1
      output.first
    else
      output
    end
  end

  def run_command(*commands)
    commands.map do |cmd|
      warn "=> Running `#{cmd}`"

      `#{cmd}`.strip
    end
  end
end

if $0 == __FILE__
  require 'rspec/autorun'

  RSpec.describe EESpecificCheck do
    subject { Class.new { include EESpecificCheck }.new }

    before do
      allow(subject).to receive(:warn)

      EESpecificCheck.private_instance_methods.each do |name|
        subject.class.__send__(:public, name) # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    describe '.run_git_command' do
      it 'returns the single output when there is a single command' do
        output = subject.run_git_command('status')

        expect(output).to be_kind_of(String)
        expect(subject).to have_received(:warn).with(/git status/)
      end

      it 'returns an array of output for more commands' do
        output = subject.run_git_command('status', 'help')

        expect(output).to all(be_a(String))
        expect(subject).to have_received(:warn).with(/git status/)
        expect(subject).to have_received(:warn).with(/git help/)
      end
    end

    describe '.find_merge_base' do
      context 'when it cannot find the merge base' do
        before do
          allow(subject).to receive(:say)
          allow(subject).to receive(:exit)

          expect(subject).to receive(:run_git_command).and_return('')
        end

        it 'calls exit(253) to fail the job and ask run it locally' do
          subject.find_merge_base('master', 'HEAD')

          expect(subject).to have_received(:say)
            .with(Regexp.union('./scripts/ee-specific-lines-check'))
          expect(subject).to have_received(:exit)
            .with(253)
        end
      end

      context 'when it found the merge base' do
        before do
          expect(subject).to receive(:run_git_command).and_return('deadbeef')
        end

        it 'returns the found merge base' do
          output = subject.find_merge_base('master', 'HEAD')

          expect(output).to eq('deadbeef')
        end
      end
    end

    describe '.matching_ce_refs' do
      before do
        expect(subject).to receive(:current_branch).and_return(ee_branch)
        expect(subject).to receive(:run_git_command)
          .and_return(ls_remote_output)
      end

      describe 'simple cases' do
        let(:ls_remote_output) do
          <<~OUTPUT
          d6602ec5194c87b0fc87103ca4d67251c76f233a\trefs/tags/v9
          f25a265a342aed6041ab0cc484224d9ca54b6f41\trefs/tags/v9.12
          c5db5456ae3b0873fc659c19fafdde22313cc441\trefs/tags/v9.123
          0918385dbd9656cab0d1d81ba7453d49bbc16250\trefs/heads/v9.x
          28862662b749fe981386814e2dba87b0e72c1eab\trefs/remotes/remote_mirror_3059/v9-to-fix-http-case-problems
          5e3496802098c86050c5b463507f3a68a83a9f02\trefs/remotes/remote_mirror_3059/29036-use-slack-service-v9
          OUTPUT
        end

        context 'with a ee- prefix' do
          let(:ee_branch) { 'ee-v9' }

          it 'sorts by matching size' do
            expect(subject.matching_ce_refs).to eq(%w[v9 v9.x v9.12 v9.123])
          end
        end

        context 'with a -ee suffix' do
          let(:ee_branch) { 'v9-ee' }

          it 'sorts by matching size' do
            expect(subject.matching_ce_refs).to eq(%w[v9 v9.x v9.12 v9.123])
          end
        end
      end

      describe 'with ambiguous branch name' do
        let(:ls_remote_output) do
          <<~OUTPUT
          954d7119384c9f2a3c862bac97beb641eb8755d6\trefs/heads/feature/sm/35954-expand-kubernetesservice-to-use-username-password
          954d7119384c9f2a3c862bac97beb641eb8755d6\trefs/heads/ce-to-ee-231
          954d7119384c9f2a3c862bac97beb641eb8755d6\trefs/heads/ce-to-ee-2
          954d7119384c9f2a3c862bac97beb641eb8755d6\trefs/heads/ce-to-1
          954d7119384c9f2a3c862bac97beb641eb8755d6\trefs/heads/ee-to-ce-123
          954d7119384c9f2a3c862bac97beb641eb8755d6\trefs/heads/ee-to-ce-12
          954d7119384c9f2a3c862bac97beb641eb8755d6\trefs/heads/to-ce-1
          28862662b749fe981386814e2dba87b0e72c1eab\trefs/remotes/remote_mirror_3059/27056-upgrade-vue-resource-to-1-0-3-to-fix-http-case-problems
          5e3496802098c86050c5b463507f3a68a83a9f02\trefs/remotes/remote_mirror_3059/29036-use-slack-service-to-notify-of-failed-pipelines
          OUTPUT
        end

        context 'with a ee- prefix' do
          let(:ee_branch) { 'ee-to-ce' }
          let(:minimal_ce_branch) { 'to-ce' }

          it 'sorts by matching size' do
            expect(subject.matching_ce_refs).to eq(%w[to-ce-1 ee-to-ce-12 ee-to-ce-123])
          end
        end

        context 'with a -ee suffix' do
          let(:ee_branch) { 'ce-to-ee' }
          let(:minimal_ce_branch) { 'ce-to' }

          it 'sorts by matching size' do
            expect(subject.matching_ce_refs).to eq(%w[ce-to-1 ce-to-ee-2 ce-to-ee-231])
          end
        end
      end
    end
  end
end
