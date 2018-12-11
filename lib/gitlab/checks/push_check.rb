# frozen_string_literal: true

module Gitlab
  module Checks
    class PushCheck < BaseChecker
      def validate!
        logger.log_timed("Checking if you are allowed to push...") do
          unless can_push?
            raise GitAccess::UnauthorizedError, 'You are not allowed to push code to this project.'
          end
        end
      end

      private

      def can_push?
        user_access.can_do_action?(:push_code) ||
          user_access.can_push_to_branch?(branch_name)
      end
    end
  end
end
