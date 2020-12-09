# frozen_string_literal: true

module Gitlab
  module Checks
    class PushCheck < BaseChecker
      def validate!
        logger.log_timed("Checking if you are allowed to push...") do
          unless can_push?
            raise GitAccess::ForbiddenError, GitAccess::ERROR_MESSAGES[:push_code]
          end
        end
      end

      private

      def can_push?
        user_access_can_push? ||
          project.branch_allows_collaboration?(user_access.user, branch_name)
      end

      def user_access_can_push?
        if Feature.enabled?(:deploy_keys_on_protected_branches, project)
          user_access.can_push_to_branch?(ref)
        else
          user_access.can_do_action?(:push_code)
        end
      end
    end
  end
end
