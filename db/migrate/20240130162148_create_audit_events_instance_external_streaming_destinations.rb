# frozen_string_literal: true

class CreateAuditEventsInstanceExternalStreamingDestinations < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    create_table :audit_events_instance_external_streaming_destinations do |t|
      t.timestamps_with_timezone null: false
      t.integer :type, null: false, limit: 2
      t.text :name, null: false, limit: 72
      t.jsonb :config, null: false
      t.binary :encrypted_secret_token, null: false
      t.binary :encrypted_secret_token_iv, null: false
    end
  end
end
