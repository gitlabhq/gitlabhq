# frozen_string_literal: true

module Import
  module SourceUsers
    class ReassignService < BaseService
      def initialize(import_source_user, assignee_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
        @assignee_user = assignee_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)
        return error_invalid_status unless import_source_user.reassignable_status?
        return error_invalid_assignee unless valid_assignee?(assignee_user)

        if reassign_user
          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      attr_reader :import_source_user, :current_user, :assignee_user

      def reassign_user
        import_source_user.reassign_to_user = assignee_user
        import_source_user.reassigned_by_user = current_user
        import_source_user.reassign
      end

      def error_invalid_assignee
        ServiceResponse.error(
          message: s_('Import|Only active regular, auditor, or administrator users can be assigned'),
          reason: :invalid_assignee,
          payload: import_source_user
        )
      end

      def valid_assignee?(user)
        user.present? && user.human? && user.active?
      end
    end
  end
end
