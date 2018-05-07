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

  CompareBase = Struct.new(:ce_merge_base, :ee_merge_base, :ce_updated_base)

  module_function

  def say(message)
    puts "\n#{message}", "\n" # puts would eat trailing newline
  end

  def find_compare_base
    setup_canonical_remotes

    ce_fetch_head = fetch_remote_ce_branch
    ce_merge_base = run_git_command("merge-base canonical-ce/master canonical-ee/master")
    ee_merge_base = run_git_command("merge-base canonical-ee/master HEAD")

    ce_updated_base =
      if ce_fetch_head.start_with?('canonical-ce')
        ce_merge_base # Compare with merge-base if no specific CE branch
      else
        checkout_and_rebase_ce_fetch_head_onto_ce_merge_base(ce_merge_base, ce_fetch_head)
      end

    CompareBase.new(ce_merge_base, ee_merge_base, ce_updated_base)
  end

  def setup_canonical_remotes
    run_git_command(
      "remote add canonical-ee https://gitlab.com/gitlab-org/gitlab-ee.git",
      "remote add canonical-ce https://gitlab.com/gitlab-org/gitlab-ce.git",
      "fetch canonical-ee master --quiet",
      "fetch canonical-ce master --quiet")
  end

  def fetch_remote_ce_branch
    remote_to_fetch, branch_to_fetch = find_remote_ce_branch

    run_git_command("fetch #{remote_to_fetch} #{branch_to_fetch} --quiet")

    "#{remote_to_fetch}/#{branch_to_fetch}"
  end

  def checkout_and_rebase_ce_fetch_head_onto_ce_merge_base(ce_merge_base, ce_fetch_head)
    # So that we could switch back
    head = head_commit_sha

    # Use detached HEAD so that we don't update HEAD
    run_git_command("checkout #{ce_fetch_head}")

    # We rebase onto the commit which is the latest commit presented in both
    # CE and EE, i.e. ce_merge_base, cutting off commits aren't merged into
    # EE yet. Here's an example:
    #
    # * o: Relevant commits
    # * x: Irrelevant commits
    # * !: Commits we want to cut off from CE branch
    #
    #                ^-> o CE branch (ce_fetch_head)
    #               /
    #     o -> o -> ! -> x CE master
    #          v (ce_merge_base)
    #     o -> o -> o -> x EE master
    #               \ (ee_merge_base)
    #                v-> o EE branch
    #
    # We want to rebase above into this: (we only change the connection)
    #
    #            -> - -> o CE branch (ce_fetch_head)
    #           /
    #     o -> o -> ! -> x CE master
    #          v (ce_merge_base)
    #     o -> o -> o -> x EE master
    #               \ (ee_merge_base)
    #                v-> o EE branch
    #
    # Therefore we rebase onto ce_merge_base, which is based off CE master,
    # for the CE branch (ce_fetch_head), effective remove the commit marked
    # as ! in the graph for CE branch. We need to remove it because it's not
    # merged into EE yet, therefore won't be available in the EE branch.
    #
    # After rebase is done, then we could compare against
    # ce_merge_base..ee_merge_base along with ce_fetch_head..HEAD (EE branch)
    # where ce_merge_base..ee_merge_base is the update-to-date
    # CE/EE difference and ce_fetch_head..HEAD is the changes we made in
    # CE and EE branches.
    run_git_command("rebase --onto #{ce_merge_base} canonical-ce/master #{ce_fetch_head}")

    status = git_status

    if status == ''
      head_commit_sha
    else
      say <<~MESSAGE
        💥 Git status not clean! This shouldn't happen. Please create an issue
        💥 and ping @godfat to investigate.

        ⚠️ Git status:

        #{status}
      MESSAGE

      run_git_command("rebase --abort")

      exit(255)
    end

  ensure # ensure would still run if we call exit, don't worry
    # Make sure to switch back
    run_git_command("checkout #{head}")
  end

  def head_commit_sha
    run_git_command("rev-parse HEAD")
  end

  def git_status
    run_git_command("status --porcelain")
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
    ls_remote_output = run_git_command("ls-remote #{ce_repo_url} \"*#{minimal_ce_branch_name}*\"")

    if ls_remote_output.include?(minimal_ce_branch_name)
      branch_to_fetch = ls_remote_output.scan(%r{(?<=refs/heads/).+}).sort_by(&:size).first

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

  def current_branch
    @current_branch ||= ENV.fetch('CI_COMMIT_REF_NAME', `git rev-parse --abbrev-ref HEAD`).strip
  end

  def minimal_ce_branch_name
    @minimal_ce_branch_name ||= current_branch.sub(/(\Aee\-|\-ee\z)/, '')
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
      puts "=> Running `#{cmd}`"

      `#{cmd}`.strip
    end
  end
end

if $0 == __FILE__
  require 'rspec/autorun'

  RSpec.describe EESpecificCheck do
    include EESpecificCheck

    before do
      allow(self).to receive(:puts)
    end

    describe '.run_git_command' do
      it 'returns the single output when there is a single command' do
        output = run_git_command('status')

        expect(output).to be_kind_of(String)
        expect(self).to have_received(:puts).with(/git status/)
      end

      it 'returns an array of output for more commands' do
        output = run_git_command('status', 'help')

        expect(output).to all(be_a(String))
        expect(self).to have_received(:puts).with(/git status/)
        expect(self).to have_received(:puts).with(/git help/)
      end
    end
  end
end
