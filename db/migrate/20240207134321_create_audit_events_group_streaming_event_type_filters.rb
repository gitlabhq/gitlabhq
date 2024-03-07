# frozen_string_literal: true

class CreateAuditEventsGroupStreamingEventTypeFilters < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  enable_lock_retries!

  INDEX_NAME = 'uniq_audit_group_event_filters_destination_id_and_event_type'
  NAMESPACE_INDEX_NAME = 'idx_audit_events_namespace_event_type_filters_on_group_id'

  def change
    create_table :audit_events_group_streaming_event_type_filters do |t|
      t.timestamps_with_timezone null: false
      t.references :external_streaming_destination,
        null: false,
        index: false,
        foreign_key: { to_table: 'audit_events_group_external_streaming_destinations', on_delete: :cascade }
      t.references :namespace, null: false,
        index: { name: NAMESPACE_INDEX_NAME },
        foreign_key: { on_delete: :cascade }
      t.text :audit_event_type, null: false, limit: 255
      t.index [:external_streaming_destination_id, :audit_event_type], unique: true, name: INDEX_NAME
    end
  end
end
