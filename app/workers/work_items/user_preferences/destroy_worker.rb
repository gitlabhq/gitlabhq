# frozen_string_literal: true

module WorkItems
  module UserPreferences
    class DestroyWorker
      include Gitlab::EventStore::Subscriber

      data_consistency :delayed
      feature_category :seat_cost_management
      urgency :low
      idempotent!
      deduplicate :until_executed

      def handle_event(event)
        payload = event.is_a?(::Gitlab::EventStore::CloudEvent) ? event.event_data : event.data

        # Legacy DestroyedEvent carries `member.source_type` (`Namespace`/`Project`);
        # DestroyedCloudEvent derives it from the source class (`Group`/`Project`).
        # Only `Group` needs adding: `Project.name == ProjectMember::SOURCE_TYPE`, but
        # `GroupMember::SOURCE_TYPE` is `Namespace`, not `Group`.
        case payload[:source_type]
        when GroupMember::SOURCE_TYPE, Group.name
          ::WorkItems::UserPreference.delete_by(
            user_id: payload[:user_id],
            namespace_id: payload[:source_id]
          )
        when ProjectMember::SOURCE_TYPE
          ::WorkItems::UserPreference.delete_by(
            user_id: payload[:user_id],
            namespace: Project.project_namespace_for(id: payload[:source_id])
          )
        end
      end
    end
  end
end
