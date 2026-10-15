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
        payload = event.event_data

        case payload[:source_type]
        when Group.name
          ::WorkItems::UserPreference.delete_by(
            user_id: payload[:user_id],
            namespace_id: payload[:source_id]
          )
        when Project.name
          ::WorkItems::UserPreference.delete_by(
            user_id: payload[:user_id],
            namespace: Project.project_namespace_for(id: payload[:source_id])
          )
        end
      end
    end
  end
end
