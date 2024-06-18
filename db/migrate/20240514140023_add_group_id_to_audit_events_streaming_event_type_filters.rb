# frozen_string_literal: true

class AddGroupIdToAuditEventsStreamingEventTypeFilters < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :audit_events_streaming_event_type_filters, :group_id, :bigint
  end
end
