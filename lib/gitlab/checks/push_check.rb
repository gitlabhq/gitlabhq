# frozen_string_literal: true

module Gitlab
  module Checks
    class PushCheck < BaseSingleChecker
      def validate!
        logger.log_timed("Checking if you are allowed to push...") do
          unless can_push?
            raise GitAccess::ForbiddenError, GitAccess::ERROR_MESSAGES[:push_code]
          end
        end
      end

      private

      def can_push?
        user_access.can_push_for_ref?(ref) ||
          project.branch_allows_collaboration?(user_access.user, branch_name)
      end
    end
  end
end
