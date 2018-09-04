# frozen_string_literal: true

module EESpecificCheck
  WHITELIST = [
    'CHANGELOG-EE.md',
    'config/**/*', # https://gitlab.com/gitlab-org/gitlab-ee/issues/4946
    'doc/**/*', # https://gitlab.com/gitlab-org/gitlab-ee/issues/4948#note_59945483
    'qa/**/*', # https://gitlab.com/gitlab-org/gitlab-ee/issues/4997#note_59764702
    'scripts/**/*',
    'spec/javascripts/**/*', # https://gitlab.com/gitlab-org/gitlab-ee/issues/3871
    'vendor/assets/javascripts/jasmine-jquery.js',
    '.gitlab-ci.yml',
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
    ce_fetch_base = run_git_command("merge-base canonical-ce/master #{ce_fetch_head}")
    ee_fetch_base = run_git_command("merge-base canonical-ee/master HEAD")
    ce_merge_base = run_git_command("merge-base #{ce_fetch_head} #{ee_fetch_head}")

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
      run_git_command("diff #{from}..#{to} --numstat -- . ':!ee'"))
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
    @ce_repo_url ||= ENV.fetch('CI_REPOSITORY_URL', 'https://gitlab.com/gitlab-org/gitlab-ce.git').sub('gitlab-ee', 'gitlab-ce')
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
        .scan(%r{(?<=refs/heads/|refs/tags/).+}).sort_by(&:size)
  end

  def scan_diff_numstat(numstat)
    numstat.scan(/(\d+)\s+(\d+)\s+(.+)/)
      .each_with_object({}) do |(added, deleted, file), result|
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
    before do
      extend EESpecificCheck

      allow(self).to receive(:warn)
    end

    describe '.run_git_command' do
      # rubocop: disable CodeReuse/ActiveRecord
      it 'returns the single output when there is a single command' do
        output = run_git_command('status')

        expect(output).to be_kind_of(String)
        expect(self).to have_received(:warn).with(/git status/)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      it 'returns an array of output for more commands' do
        output = run_git_command('status', 'help')

        expect(output).to all(be_a(String))
        expect(self).to have_received(:warn).with(/git status/)
        expect(self).to have_received(:warn).with(/git help/)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    describe '.matching_ce_refs' do
      before do
        expect(self).to receive(:current_branch).and_return('v9')
        expect(self).to receive(:run_git_command)
          .and_return(<<~OUTPUT)
            d6602ec5194c87b0fc87103ca4d67251c76f233a\trefs/tags/v9
            f25a265a342aed6041ab0cc484224d9ca54b6f41\trefs/tags/v9.12
            c5db5456ae3b0873fc659c19fafdde22313cc441\trefs/tags/v9.123
            0918385dbd9656cab0d1d81ba7453d49bbc16250\trefs/heads/v9.x
          OUTPUT
      end

      it 'sorts by matching size' do
        expect(matching_ce_refs).to eq(%w[v9 v9.x v9.12 v9.123])
      end
    end
  end
end
