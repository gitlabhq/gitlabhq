# frozen_string_literal: true

module Gitlab
  module Checks
    class TagCheck < BaseSingleChecker
      ERROR_MESSAGES = {
        change_existing_tags: 'You are not allowed to change existing tags on this project.',
        update_protected_tag: 'Protected tags cannot be updated.',
        delete_protected_tag: 'You are not allowed to delete protected tags from this project. ' \
                              'Only a project maintainer or owner can delete a protected tag.',
        delete_protected_tag_non_web: 'You can only delete protected tags using the web interface.',
        create_protected_tag: 'You are not allowed to create this tag as it is protected.',
        default_branch_collision: 'You cannot use default branch name to create a tag',
        prohibited_tag_name: 'You cannot create a tag with a prohibited pattern.',
        prohibited_sha_tag_name: 'You cannot create a tag with a SHA-1 or SHA-256 tag name.',
        prohibited_tag_name_encoding: 'Tag names must be valid when converted to UTF-8 encoding'
      }.freeze

      LOG_MESSAGES = {
        tag_checks: "Checking if you are allowed to change existing tags...",
        default_branch_collision_check: "Checking if you are providing a valid tag name...",
        protected_tag_checks: "Checking if you are creating, updating or deleting a protected tag..."
      }.freeze

      STARTS_WITH_SHA_REGEX = %r{\A#{Gitlab::Git::Commit::RAW_FULL_SHA_PATTERN}}o

      def validate!
        return unless tag_name

        logger.log_timed(LOG_MESSAGES[:tag_checks]) { tag_checks }
        logger.log_timed(LOG_MESSAGES[:default_branch_collision_check]) { default_branch_collision_check }
        prohibited_tag_checks
        logger.log_timed(LOG_MESSAGES[:protected_tag_checks]) { protected_tag_checks }
      end

      private

      def tag_checks
        return unless tag_exists? && user_access.cannot_do_action?(:admin_tag)

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:change_existing_tags]
      end

      def default_branch_collision_check
        return unless creation? && tag_name == project.default_branch

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:default_branch_collision]
      end

      def prohibited_tag_checks
        return if deletion?

        # Incorrectly encoded tags names may raise during other checks so we
        # need to validate the encoding first
        validate_encoding!
        validate_valid_tag_name!
        validate_tag_name_not_fully_qualified!
        validate_tag_name_not_sha_like!
      end

      def protected_tag_checks
        return unless ProtectedTag.protected?(project, tag_name)

        validate_protected_tag_update!
        validate_protected_tag_deletion!
        validate_protected_tag_creation!
      end

      def validate_encoding!
        return unless Feature.enabled?(:prohibited_tag_name_encoding_check, project)
        return if Gitlab::EncodingHelper.force_encode_utf8(tag_name).valid_encoding?

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:prohibited_tag_name_encoding]
      end

      def validate_valid_tag_name!
        return if Gitlab::GitRefValidator.validate(tag_name)

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:prohibited_tag_name]
      end

      def validate_tag_name_not_fully_qualified!
        return unless tag_name.start_with?("refs/tags/")

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:prohibited_tag_name]
      end

      def validate_protected_tag_update!
        return unless update?

        raise(GitAccess::ForbiddenError, ERROR_MESSAGES[:update_protected_tag])
      end

      def validate_protected_tag_deletion!
        return unless deletion?

        unless user_access.user.can?(:maintainer_access, project)
          raise(GitAccess::ForbiddenError, ERROR_MESSAGES[:delete_protected_tag])
        end

        return if updated_from_web?

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:delete_protected_tag_non_web]
      end

      def validate_protected_tag_creation!
        return if user_access.can_create_tag?(tag_name)

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:create_protected_tag]
      end

      def validate_tag_name_not_sha_like!
        return unless STARTS_WITH_SHA_REGEX.match?(tag_name)

        raise GitAccess::ForbiddenError, ERROR_MESSAGES[:prohibited_sha_tag_name]
      end
    end
  end
end
