# frozen_string_literal: true

module Import
  module SourceUsers
    class ResendNotificationService < BaseService
      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)
        return error_invalid_status unless import_source_user.awaiting_approval?

        send_user_reassign_email

        ServiceResponse.success(payload: import_source_user)
      end
    end
  end
end
