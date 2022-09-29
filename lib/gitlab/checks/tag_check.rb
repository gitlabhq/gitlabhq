# frozen_string_literal: true

module Gitlab
  module Checks
    class TagCheck < BaseSingleChecker
      ERROR_MESSAGES = {
        change_existing_tags: 'You are not allowed to change existing tags on this project.',
        update_protected_tag: 'Protected tags cannot be updated.',
        delete_protected_tag: 'You are not allowed to delete protected tags from this project. '\
          'Only a project maintainer or owner can delete a protected tag.',
        delete_protected_tag_non_web: 'You can only delete protected tags using the web interface.',
        create_protected_tag: 'You are not allowed to create this tag as it is protected.',
        default_branch_collision: 'You cannot use default branch name to create a tag'
      }.freeze

      LOG_MESSAGES = {
        tag_checks: "Checking if you are allowed to change existing tags...",
        default_branch_collision_check: "Checking if you are providing a valid tag name...",
        protected_tag_checks: "Checking if you are creating, updating or deleting a protected tag..."
      }.freeze

      def validate!
        return unless tag_name

        logger.log_timed(LOG_MESSAGES[:tag_checks]) do
          if tag_exists? && user_access.cannot_do_action?(:admin_tag)
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:change_existing_tags]
          end
        end

        default_branch_collision_check
        protected_tag_checks
      end

      private

      def protected_tag_checks
        logger.log_timed(LOG_MESSAGES[__method__]) do
          return unless ProtectedTag.protected?(project, tag_name) # rubocop:disable Cop/AvoidReturnFromBlocks

          raise(GitAccess::ForbiddenError, ERROR_MESSAGES[:update_protected_tag]) if update?

          if deletion?
            unless user_access.user.can?(:maintainer_access, project)
              raise(GitAccess::ForbiddenError, ERROR_MESSAGES[:delete_protected_tag])
            end

            unless updated_from_web?
              raise GitAccess::ForbiddenError, ERROR_MESSAGES[:delete_protected_tag_non_web]
            end
          end

          unless user_access.can_create_tag?(tag_name)
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:create_protected_tag]
          end
        end
      end

      def default_branch_collision_check
        logger.log_timed(LOG_MESSAGES[:default_branch_collision_check]) do
          if creation? && tag_name == project.default_branch
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:default_branch_collision]
          end
        end
      end
    end
  end
end
