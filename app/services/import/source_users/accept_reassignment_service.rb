# frozen_string_literal: true

module Import
  module SourceUsers
    class AcceptReassignmentService < BaseService
      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user_matches_reassign_to_user

        if import_source_user.accept
          Import::ReassignPlaceholderUserRecordsWorker.perform_async(import_source_user.id)
          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      def current_user_matches_reassign_to_user
        return false if current_user.nil?

        current_user.id == import_source_user.reassign_to_user_id
      end
    end
  end
end
