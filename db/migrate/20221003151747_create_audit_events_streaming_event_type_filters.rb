# frozen_string_literal: true

class CreateAuditEventsStreamingEventTypeFilters < Gitlab::Database::Migration[2.0]
  UNIQ_INDEX_NAME = 'unique_streaming_event_type_filters_destination_id'

  def change
    create_table :audit_events_streaming_event_type_filters do |t|
      t.timestamps_with_timezone null: false
      t.references :external_audit_event_destination,
                   null: false,
                   index: false,
                   foreign_key: { to_table: 'audit_events_external_audit_event_destinations', on_delete: :cascade }
      t.text :audit_event_type, null: false, limit: 255

      t.index [:external_audit_event_destination_id, :audit_event_type], unique: true, name: UNIQ_INDEX_NAME
    end
  end
end
