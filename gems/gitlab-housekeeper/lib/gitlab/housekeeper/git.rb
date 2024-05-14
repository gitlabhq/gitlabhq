# frozen_string_literal: true

require 'logger'
require 'gitlab/housekeeper/shell'
require 'gitlab/housekeeper/push_options'

module Gitlab
  module Housekeeper
    class Git
      HOUSEKEEPER_REMOTE = 'housekeeper'
      FALLBACK_REMOTE = 'origin'

      def initialize(logger:, branch_from: 'master')
        @logger = logger
        @branch_from = branch_from
      end

      def with_clean_state(&block)
        result = Shell.execute('git', 'stash')
        stashed = !result.include?('No local changes to save')

        with_return_to_current_branch(stashed: stashed, &block)
      end

      def create_branch(change)
        branch_name = branch_name(change.identifiers)

        Shell.execute("git", "branch", "-f", branch_name, @branch_from)

        branch_name
      end

      def in_branch(branch_name)
        with_return_to_current_branch do
          checkout_branch(branch_name)

          yield
        end
      end

      def create_commit(change)
        Shell.execute("git", "add", *change.changed_files)
        Shell.execute("git", "commit", "-m", change.commit_message)
      end

      def push(branch_name, push_options = PushOptions.new)
        push_command = ['git', 'push', '-u', '-f', housekeeper_remote, "#{branch_name}:#{branch_name}"]
        push_command << '-o ci.skip' if push_options.ci_skip

        Shell.execute(*push_command)
      end

      private

      def housekeeper_remote
        housekeeper_remote_exists? ? HOUSEKEEPER_REMOTE : FALLBACK_REMOTE
      end

      def housekeeper_remote_exists?
        Shell.execute("git", "config", "remote.#{HOUSEKEEPER_REMOTE}.url")
        true
      rescue Shell::Error
        false
      end

      def create_and_checkout_branch(branch_name)
        begin
          Shell.execute("git", "branch", '-D', branch_name)
        rescue Shell::Error # Might not exist yet
        end

        Shell.execute("git", "checkout", "-b", branch_name)
      end

      def checkout_branch(branch_name)
        Shell.execute("git", "checkout", branch_name)
      end

      def branch_name(identifiers)
        # Hyphen-case each identifier then join together with hyphens.
        branch_name = identifiers
          .map { |i| i.gsub(/[^\w]+/, '-') }
          .map { |i| i.gsub(/[[:upper:]]/) { |w| "-#{w.downcase}" } }
          .join('-')
          .delete_prefix("-")

        # Truncate if it's too long and add a digest
        if branch_name.length > 240
          branch_name = branch_name[0...200] + OpenSSL::Digest::SHA256.hexdigest(branch_name)[0...15]
        end

        branch_name
      end

      def with_return_to_current_branch(stashed: false)
        current_branch = Shell.execute('git', 'branch', '--show-current').chomp

        yield
      ensure
        # The `current_branch` won't be set in CI due to how the repo is cloned. Therefore we should only checkout
        # `current_branch` if we actually have one.
        checkout_branch(current_branch) if current_branch.present?
        Shell.execute('git', 'stash', 'pop') if stashed
      end
    end
  end
end
