# frozen_string_literal: true

class CreateAuditEventsGroupExternalStreamingDestinations < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  NAMESPACE_INDEX_NAME = 'idx_audit_events_group_external_destinations_on_group_id'

  def change
    create_table :audit_events_group_external_streaming_destinations do |t|
      t.timestamps_with_timezone null: false
      t.references :group, null: false,
        index: { name: NAMESPACE_INDEX_NAME },
        foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.integer :type, null: false, limit: 2
      t.text :name, null: false, limit: 72
      t.jsonb :config, null: false
      t.binary :encrypted_secret_token, null: false
      t.binary :encrypted_secret_token_iv, null: false
    end
  end
end
