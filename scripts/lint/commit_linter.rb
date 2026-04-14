#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab/dangerfiles/commit_linter'

module Lint
  module CommitLinter
    COMMIT_MESSAGE_GUIDELINES =
      "https://docs.gitlab.com/development/contributing/merge_request_workflow/#commit-messages-guidelines"
    DEFAULT_BRANCH_REF = 'origin/master'
    SHA_PATTERN = /\A[0-9a-f]{40}\z/
    CommitData = Struct.new(:message, :sha)

    module_function

    def run_command(cmd)
      output = `#{cmd}`
      [output, $?.success?] # -- backtick idiom
    end

    def lint_commit(commit)
      return if commit.message.to_s.strip.empty?

      linter = Gitlab::Dangerfiles::CommitLinter.new(commit)

      return if linter.fixup? || linter.merge? || linter.revert? || linter.suggestion?

      linter.lint
      linter if linter.failed?
    end

    # Checks whether the current commit is the first on this branch.
    #
    # In the post-commit hook context, HEAD already includes the new commit.
    # So `git rev-list merge-base..HEAD` returns the new commit plus any
    # prior commits on the branch:
    # - Exactly 1 commit in rev-list = this is the first commit (returns true)
    # - More than 1 = prior commits exist = not the first (returns false)
    #
    # On error, returns true (fail-open) so we lint rather than silently skip.
    # This may cause false positives in unusual git states (e.g. shallow clones),
    # but it's safer than letting bad messages through.
    def first_commit_on_branch?
      base_sha_output, base_success = run_command("git merge-base #{DEFAULT_BRANCH_REF} HEAD")
      base_sha = base_sha_output.strip
      return true unless base_success && base_sha.match?(SHA_PATTERN)

      shas_output, shas_success = run_command("git rev-list #{base_sha}..HEAD")
      return true unless shas_success

      shas_output.strip.split("\n").length <= 1
    end

    def commit_from_head
      return [] unless first_commit_on_branch?

      output, success = run_command("git log -1 --format='%h%n%B' HEAD")
      return [] unless success

      short_sha, message = output.strip.split("\n", 2)
      return [] if short_sha.to_s.empty?

      [CommitData.new(message.to_s.strip, short_sha)]
    end

    def commits_from_file(file_path)
      unless file_path && File.exist?(file_path)
        warn "WARNING: Commit message file not found, skipping lint."
        return []
      end

      lines = File.read(file_path).lines
      scissors_index = lines.index { |line| line.match?(/^# -+ >8 -+/) }
      lines = lines[0...scissors_index] if scissors_index
      message = lines
        .reject { |line| line.start_with?('#') }
        .join

      [CommitData.new(message, nil)]
    end

    def commits_from_git
      base_sha_output, base_success = run_command("git merge-base #{DEFAULT_BRANCH_REF} HEAD")
      base_sha = base_sha_output.strip
      unless base_success && base_sha.match?(SHA_PATTERN)
        warn "ERROR: Failed to determine merge base"
        exit 1
      end

      shas_output, shas_success = run_command("git rev-list #{base_sha}..HEAD")
      unless shas_success
        warn "ERROR: Failed to list commits"
        exit 1
      end

      first_sha = shas_output.split("\n").last
      return [] unless first_sha&.match?(SHA_PATTERN)

      output, = run_command("git log -1 --format='%h%n%B' #{first_sha}")
      short_sha, message = output.strip.split("\n", 2)
      [CommitData.new(message.to_s.strip, short_sha)]
    end

    def run(argv)
      post_commit = argv.delete('--post-commit')
      commits = if post_commit
                  commit_from_head
                elsif argv[0]
                  commits_from_file(argv[0])
                else
                  commits_from_git
                end

      return 0 if commits.empty?

      failed_linters = commits.filter_map { |commit| lint_commit(commit) }

      return 0 if failed_linters.empty?

      warn "\nCommit message linting failed:\n\n"

      failed_linters.each do |linter|
        warn "Commit #{linter.commit.sha}:" if linter.commit.sha
        linter.problems.each_value do |problem_desc|
          warn "  - #{problem_desc}"
        end
        warn ""
      end

      warn "See #{COMMIT_MESSAGE_GUIDELINES}"

      if post_commit
        warn "\nTo fix, amend your commit message with: git commit --amend"
        0
      else
        1
      end
    end
  end
end

exit Lint::CommitLinter.run(ARGV) if $PROGRAM_NAME == __FILE__
