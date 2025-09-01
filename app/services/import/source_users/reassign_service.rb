# frozen_string_literal: true

module Import
  module SourceUsers
    class ReassignService < BaseService
      include Gitlab::Utils::StrongMemoize

      def initialize(import_source_user, assignee_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
        @assignee_user = assignee_user
        @root_namespace = import_source_user.namespace.root_ancestor
      end

      def execute
        validation_error = run_validations
        return validation_error if validation_error.is_a?(ServiceResponse) && validation_error.error?

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

        unless reassign_successful
          track_reassignment_event('fail_placeholder_user_reassignment')
          return ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end

        if skip_reassignment_confirmation?
          Import::ReassignPlaceholderUserRecordsWorker.perform_async(import_source_user.id,
            'confirmation_skipped' => true)
          track_reassignment_event('reassign_placeholder_user_without_confirmation')
        else
          send_user_reassign_email
          track_reassignment_event('propose_placeholder_user_reassignment')
        end

        ServiceResponse.success(payload: import_source_user)
      end

      private

      attr_reader :assignee_user, :root_namespace

      def reassign_user
        import_source_user.reassign_to_user = assignee_user
        import_source_user.reassigned_by_user = current_user

        return import_source_user.reassign_without_confirmation if skip_reassignment_confirmation?

        import_source_user.reassign
      end

      def error_namespace_type
        ServiceResponse.error(
          message: invalid_namespace_message,
          reason: :invalid_namespace,
          payload: import_source_user
        )
      end

      def invalid_namespace_message
        s_("UserMapping|You cannot reassign user contributions of imports to a personal namespace.")
      end

      # overridden in EE
      def run_validations
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)
        return error_namespace_type if root_namespace.user_namespace?

        error_invalid_assignee unless valid_assignee?
      end

      def error_invalid_assignee
        ServiceResponse.error(
          message: invalid_assignee_message,
          reason: :invalid_assignee,
          payload: import_source_user
        )
      end

      def invalid_assignee_message
        if admin_skip_reassignment_confirmation? && allow_mapping_to_admins?
          s_('UserMapping|You can assign users with regular, auditor, or administrator access only.')
        elsif allow_mapping_to_admins?
          s_('UserMapping|You can assign active users with regular, auditor, or administrator access only.')
        elsif admin_skip_reassignment_confirmation?
          s_('UserMapping|You can assign users with regular or auditor access only.')
        else
          s_('UserMapping|You can assign active users with regular or auditor access only.')
        end
      end

      def valid_assignee?
        assignee_user.present? &&
          assignee_user.human? &&
          (admin_skip_reassignment_confirmation? || assignee_user.active?) &&
          # rubocop:disable Cop/UserAdmin -- This should not be affected by admin mode.
          # We just want to know whether the user CAN have admin privileges or not.
          (allow_mapping_to_admins? || !assignee_user.admin?)
        # rubocop:enable Cop/UserAdmin
      end

      def allow_mapping_to_admins?
        ::Gitlab::CurrentSettings.allow_contribution_mapping_to_admins?
      end

      def skip_reassignment_confirmation?
        admin_skip_reassignment_confirmation? || enterprise_skip_reassignment_confirmation?
      end

      def admin_skip_reassignment_confirmation?
        Import::UserMapping::AdminBypassAuthorizer.new(current_user).allowed?
      end
      strong_memoize_attr :admin_skip_reassignment_confirmation?

      # rubocop:disable Gitlab/NoCodeCoverageComment -- method is tested in EE
      # :nocov:
      # Overridden in EE
      def enterprise_skip_reassignment_confirmation?
        false
      end
      # :nocov:
      # rubocop:enable Gitlab/NoCodeCoverageComment
    end
  end
end

Import::SourceUsers::ReassignService.prepend_mod
