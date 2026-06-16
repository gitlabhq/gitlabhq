# frozen_string_literal: true

class AddKindToAuditEventsGroupStreamingEventTypeFilters < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :audit_events_group_streaming_event_type_filters,
      :kind,
      :integer,
      limit: 2,
      default: 0,
      null: false
  end
end
