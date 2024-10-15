# frozen_string_literal: true

module Import
  module SourceUsers
    class RejectReassignmentService < BaseService
      def initialize(import_source_user, current_user:, reassignment_token:)
        @import_source_user = import_source_user
        @current_user = current_user
        @reassignment_token = reassignment_token
      end

      def execute
        return error_invalid_status unless import_source_user.awaiting_approval?

        invalid_permissions = false
        reject_successful = false

        import_source_user.with_lock do
          next invalid_permissions = true unless current_user_matches_reassign_to_user? && reassignment_token_is_valid?

          reject_successful = import_source_user.reject
        end

        return error_invalid_permissions if invalid_permissions

        if reject_successful
          send_user_reassign_rejected_email

          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      def send_user_reassign_rejected_email
        Notify.import_source_user_rejected(import_source_user.id).deliver_now
      end

      private

      attr_reader :reassignment_token

      def current_user_matches_reassign_to_user?
        return false if current_user.nil?

        current_user.id == import_source_user.reassign_to_user_id
      end

      def reassignment_token_is_valid?
        reassignment_token == import_source_user.reassignment_token
      end
    end
  end
end
