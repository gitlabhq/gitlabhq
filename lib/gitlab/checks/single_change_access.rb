# frozen_string_literal: true

module Gitlab
  module Checks
    class SingleChangeAccess
      ATTRIBUTES = %i[user_access project skip_authorization
                      protocol oldrev newrev ref
                      branch_name tag_name logger commits gitaly_context push_options].freeze

      attr_reader(*ATTRIBUTES)

      def initialize(
        change, user_access:, project:,
        protocol:, logger:, commits: nil, gitaly_context: nil, push_options: nil
      )
        @oldrev, @newrev, @ref = change.values_at(:oldrev, :newrev, :ref)
        @branch_ref = Gitlab::Git.branch_ref?(@ref)
        @branch_name = Gitlab::Git.branch_name(@ref)
        @tag_ref = Gitlab::Git.tag_ref?(@ref)
        @tag_name = Gitlab::Git.tag_name(@ref)
        @user_access = user_access
        @project = project
        @protocol = protocol
        @commits = commits
        @gitaly_context = gitaly_context
        @push_options = push_options
        @logger = logger
        @logger.append_message("Running checks for ref: #{@branch_name || @tag_name}")
      end

      def validate!
        ref_level_checks
        # Check of commits should happen as the last step
        # given they're expensive in terms of performance
        commits_check

        true
      end

      def commits
        @commits ||= project.repository.new_commits(newrev)
      end

      def branch_ref?
        @branch_ref
      end

      def tag_ref?
        @tag_ref
      end

      protected

      def ref_level_checks
        Gitlab::Checks::PushCheck.new(self).validate!
        Gitlab::Checks::BranchCheck.new(self).validate!
        Gitlab::Checks::TagCheck.new(self).validate!
        Gitlab::Checks::Security::PolicyCheck.new(self).validate!
      end

      def commits_check
        Gitlab::Checks::CommitsCheck.new(self).validate!
        Gitlab::Checks::DiffCheck.new(self).validate!
      end
    end
  end
end

Gitlab::Checks::SingleChangeAccess.prepend_mod_with('Gitlab::Checks::SingleChangeAccess')
