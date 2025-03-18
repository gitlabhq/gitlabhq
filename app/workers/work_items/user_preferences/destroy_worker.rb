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
        case event.data[:source_type]
        when GroupMember::SOURCE_TYPE
          ::WorkItems::UserPreference.delete_by(
            user_id: event.data[:user_id],
            namespace_id: event.data[:source_id]
          )
        when ProjectMember::SOURCE_TYPE
          ::WorkItems::UserPreference.delete_by(
            user_id: event.data[:user_id],
            namespace: Project.project_namespace_for(id: event.data[:source_id])
          )
        end
      end
    end
  end
end
