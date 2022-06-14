# frozen_string_literal: true

class CreateAuditEventsStreamingHeaders < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'idx_streaming_headers_on_external_audit_event_destination_id'
  UNIQ_INDEX_NAME = 'idx_external_audit_event_destination_id_key_uniq'

  def change
    create_table :audit_events_streaming_headers do |t|
      t.timestamps_with_timezone null: false
      t.references :external_audit_event_destination,
                   null: false,
                   index: { name: INDEX_NAME },
                   foreign_key: { to_table: 'audit_events_external_audit_event_destinations', on_delete: :cascade }
      t.text :key, null: false, limit: 255
      t.text :value, null: false, limit: 255

      t.index [:key, :external_audit_event_destination_id], unique: true, name: UNIQ_INDEX_NAME
    end
  end
end
