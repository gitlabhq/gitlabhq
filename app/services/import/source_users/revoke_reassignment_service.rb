# frozen_string_literal: true

module Import
  module SourceUsers
    class RevokeReassignmentService < BaseService
      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
      end

      def execute
        return error_invalid_status unless import_source_user.completed?

        invalid_permissions = false
        revoke_successful = false

        import_source_user.with_lock do
          next invalid_permissions = true unless current_user_matches_reassign_to_user?

          revoke_successful = import_source_user.revoke
        end

        return error_invalid_permissions if invalid_permissions

        if revoke_successful
          track_reassignment_event('revoke_placeholder_user_reassignment')

          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      def current_user_matches_reassign_to_user?
        return false if current_user.nil?

        current_user.id == import_source_user.reassign_to_user_id
      end
    end
  end
end
