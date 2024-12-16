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
        return error_invalid_assignee unless valid_assignee?(assignee_user)

        invalid_status = false
        reassign_successful = false

        import_source_user.with_lock do
          if import_source_user.reassignable_status?
            reassign_successful = reassign_user
          else
            invalid_status = true
          end
        end

        return error_invalid_status if invalid_status

        if reassign_successful
          send_user_reassign_email

          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      attr_reader :assignee_user

      def reassign_user
        import_source_user.reassign_to_user = assignee_user
        import_source_user.reassigned_by_user = current_user
        import_source_user.reassign
      end

      def error_invalid_assignee
        ServiceResponse.error(
          message: invalid_assignee_message,
          reason: :invalid_assignee,
          payload: import_source_user
        )
      end

      def invalid_assignee_message
        if allow_mapping_to_admins?
          s_('UserMapping|You can assign users with regular, auditor, or administrator access only.')
        else
          s_('UserMapping|You can assign only active users with regular or auditor access. ' \
            'To assign users with administrator access, ask your GitLab administrator to ' \
            'enable the "Allow contribution mapping to administrators" setting.')
        end
      end

      def valid_assignee?(user)
        user.present? &&
          user.human? &&
          user.active? &&
          # rubocop:disable Cop/UserAdmin -- This should not be affected by admin mode.
          # We just want to know whether the user CAN have admin privileges or not.
          (allow_mapping_to_admins? ? true : !user.admin?)
        # rubocop:enable Cop/UserAdmin
      end

      def allow_mapping_to_admins?
        ::Gitlab::CurrentSettings.allow_contribution_mapping_to_admins?
      end
    end
  end
end
