# frozen_string_literal: true

module Import
  module SourceUsers
    class KeepAsPlaceholderService < BaseService
      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)
        return error_invalid_status unless import_source_user.reassignable_status?

        if keep_as_placeholder
          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      def keep_as_placeholder
        import_source_user.reassign_to_user = nil
        import_source_user.reassigned_by_user = current_user
        import_source_user.keep_as_placeholder
      end
    end
  end
end
