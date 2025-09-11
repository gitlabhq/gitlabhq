# frozen_string_literal: true

module Import
  module SourceUsers
    class UndoKeepAsPlaceholderService < BaseService
      attr_reader :placeholder_user

      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @placeholder_user = import_source_user.placeholder_user
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)

        invalid_status = false
        undo_successful = false

        import_source_user.with_lock do
          if import_source_user.keep_as_placeholder?
            undo_successful = undo_keep_as_placeholder
          else
            invalid_status = true
          end
        end

        return error_invalid_status if invalid_status

        if undo_successful
          track_reassignment_event('undo_keep_as_placeholder', reassign_to_user: placeholder_user)

          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      def undo_keep_as_placeholder
        import_source_user.undo_keep_as_placeholder
      end
    end
  end
end
