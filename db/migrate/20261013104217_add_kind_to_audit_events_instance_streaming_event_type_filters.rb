# frozen_string_literal: true

class AddKindToAuditEventsInstanceStreamingEventTypeFilters < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    add_column :audit_events_instance_streaming_event_type_filters,
      :kind,
      :integer,
      limit: 2,
      default: 0,
      null: false
  end
end
