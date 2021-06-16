# frozen_string_literal: true

module Gitlab
  module Checks
    class TagCheck < BaseSingleChecker
      ERROR_MESSAGES = {
        change_existing_tags: 'You are not allowed to change existing tags on this project.',
        update_protected_tag: 'Protected tags cannot be updated.',
        delete_protected_tag: 'Protected tags cannot be deleted.',
        create_protected_tag: 'You are not allowed to create this tag as it is protected.'
      }.freeze

      LOG_MESSAGES = {
        tag_checks: "Checking if you are allowed to change existing tags...",
        protected_tag_checks: "Checking if you are creating, updating or deleting a protected tag..."
      }.freeze

      def validate!
        return unless tag_name

        logger.log_timed(LOG_MESSAGES[:tag_checks]) do
          if tag_exists? && user_access.cannot_do_action?(:admin_tag)
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:change_existing_tags]
          end
        end

        protected_tag_checks
      end

      private

      def protected_tag_checks
        logger.log_timed(LOG_MESSAGES[__method__]) do
          return unless ProtectedTag.protected?(project, tag_name) # rubocop:disable Cop/AvoidReturnFromBlocks

          raise(GitAccess::ForbiddenError, ERROR_MESSAGES[:update_protected_tag]) if update?
          raise(GitAccess::ForbiddenError, ERROR_MESSAGES[:delete_protected_tag]) if deletion?

          unless user_access.can_create_tag?(tag_name)
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:create_protected_tag]
          end
        end
      end
    end
  end
end
