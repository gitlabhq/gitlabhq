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

        # Notifier will be added in https://gitlab.com/gitlab-org/gitlab/-/issues/455912

        ServiceResponse.success(payload: import_source_user)
      end

      private

      attr_reader :import_source_user, :current_user
    end
  end
end
