# frozen_string_literal: true

module Import
  module SourceUsers
    class CancelReassignmentService < BaseService
      attr_reader :reassign_to_user

      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @reassign_to_user = import_source_user.reassign_to_user
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)

        invalid_status = false
        cancel_successful = false

        import_source_user.with_lock do
          if import_source_user.cancelable_status?
            cancel_successful = cancel_reassignment
          else
            invalid_status = true
          end
        end

        return error_invalid_status if invalid_status

        if cancel_successful
          track_reassignment_event(
            'cancel_placeholder_user_reassignment',
            reassign_to_user: reassign_to_user
          )

          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      def cancel_reassignment
        import_source_user.reassign_to_user = nil
        import_source_user.reassigned_by_user = nil
        import_source_user.cancel_reassignment
      end
    end
  end
end
