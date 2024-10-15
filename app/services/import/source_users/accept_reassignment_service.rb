# frozen_string_literal: true

module Import
  module SourceUsers
    class AcceptReassignmentService < BaseService
      def initialize(import_source_user, current_user:, reassignment_token:)
        @import_source_user = import_source_user
        @current_user = current_user
        @reassignment_token = reassignment_token
      end

      def execute
        invalid_permissions = false
        accept_successful = false

        import_source_user.with_lock do
          next invalid_permissions = true unless current_user_matches_reassign_to_user? && reassignment_token_is_valid?

          accept_successful = import_source_user.accept
        end

        return error_invalid_permissions if invalid_permissions

        if accept_successful
          Import::ReassignPlaceholderUserRecordsWorker.perform_async(import_source_user.id)
          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
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
