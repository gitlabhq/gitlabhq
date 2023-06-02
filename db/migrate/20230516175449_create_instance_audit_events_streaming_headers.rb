# frozen_string_literal: true

class CreateInstanceAuditEventsStreamingHeaders < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'idx_headers_instance_external_audit_event_destination_id'
  UNIQ_INDEX_NAME = 'idx_instance_external_audit_event_destination_id_key_uniq'

  def change
    create_table :instance_audit_events_streaming_headers do |t|
      t.timestamps_with_timezone null: false
      t.references :instance_external_audit_event_destination,
        null: false,
        index: { name: INDEX_NAME },
        foreign_key: { to_table: 'audit_events_instance_external_audit_event_destinations', on_delete: :cascade }
      t.text :key, null: false, limit: 255
      t.text :value, null: false, limit: 255

      t.index [:instance_external_audit_event_destination_id, :key], unique: true, name: UNIQ_INDEX_NAME
    end
  end
end
