# frozen_string_literal: true

module Import
  module SourceUsers
    class BaseService
      include Gitlab::InternalEventsTracking

      private

      attr_reader :import_source_user, :current_user

      def error_invalid_permissions
        ServiceResponse.error(
          message: s_('Import|You have insufficient permissions to update the import source user'),
          reason: :forbidden
        )
      end

      def error_invalid_status
        ServiceResponse.error(
          message: s_('Import|Import source user has an invalid status for this operation'),
          reason: :invalid_status,
          payload: import_source_user
        )
      end

      def send_user_reassign_email
        Notify.import_source_user_reassign(import_source_user.id).deliver_later
      end

      def track_reassignment_event(event_name, reassign_to_user: import_source_user.reassign_to_user)
        track_internal_event(
          event_name,
          user: current_user,
          namespace: import_source_user.namespace,
          additional_properties: {
            label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
            property: Gitlab::GlobalAnonymousId.user_id(reassign_to_user),
            import_type: import_source_user.import_type,
            reassign_to_user_state: reassign_to_user&.state
          }
        )
      end
    end
  end
end
