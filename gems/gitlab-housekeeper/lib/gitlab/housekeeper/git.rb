# frozen_string_literal: true

require 'logger'
require 'gitlab/housekeeper/shell'

module Gitlab
  module Housekeeper
    class Git
      def initialize(logger:, branch_from: 'master')
        @logger = logger
        @branch_from = branch_from
      end

      def commit_in_branch(change)
        branch_name = branch_name(change.identifiers)

        create_commit(branch_name, change)

        branch_name
      end

      def with_branch_from_branch
        stashed = false
        current_branch = Shell.execute('git', 'branch', '--show-current').chomp

        result = Shell.execute('git', 'stash')
        stashed = !result.include?('No local changes to save')

        Shell.execute("git", "checkout", @branch_from)

        yield
      ensure
        # The `current_branch` won't be set in CI due to how the repo is cloned. Therefore we should only checkout
        # `current_branch` if we actually have one.
        Shell.execute("git", "checkout", current_branch) if current_branch.present?
        Shell.execute('git', 'stash', 'pop') if stashed
      end

      def create_commit(branch_name, change)
        current_branch = Shell.execute('git', 'branch', '--show-current').chomp

        begin
          Shell.execute("git", "branch", '-D', branch_name)
        rescue Shell::Error # Might not exist yet
        end

        Shell.execute("git", "checkout", "-b", branch_name)
        Shell.execute("git", "add", *change.changed_files)
        Shell.execute("git", "commit", "-m", change.commit_message)
      ensure
        Shell.execute("git", "checkout", current_branch)
      end

      def branch_name(identifiers)
        # Hyphen-case each identifier then join together with hyphens.
        branch_name = identifiers
          .map { |i| i.gsub(/[[:upper:]]/) { |w| "-#{w.downcase}" } }
          .join('-')
          .delete_prefix("-")

        # Truncate if it's too long and add a digest
        if branch_name.length > 240
          branch_name = branch_name[0...200] + OpenSSL::Digest::SHA256.hexdigest(branch_name)[0...15]
        end

        branch_name
      end
    end
  end
end
