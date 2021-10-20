# frozen_string_literal: true

class CreateExternalAuditEventDestinationsTable < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    create_table :audit_events_external_audit_event_destinations do |t|
      t.references :namespace, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.text :destination_url, null: false, limit: 255 # rubocop:disable Migration/AddLimitToTextColumns
      t.timestamps_with_timezone null: false

      t.index [:namespace_id, :destination_url], unique: true, name: 'index_external_audit_event_destinations_on_namespace_id'
    end
  end
end
