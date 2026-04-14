# frozen_string_literal: true

module Import
  module SourceUsers
    class RetryFailedReassignmentService < BaseService
      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)

        invalid_status = false
        retry_successful = false

        import_source_user.with_lock do
          next invalid_status = true unless import_source_user.failed?

          retry_successful = import_source_user.retry_reassignment
        end

        return error_invalid_status if invalid_status

        if retry_successful
          Import::ReassignPlaceholderUserRecordsWorker.perform_async(import_source_user.id)
          track_reassignment_event('retry_failed_placeholder_user_reassignment')

          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end
    end
  end
end
