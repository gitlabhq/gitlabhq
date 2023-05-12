# frozen_string_literal: true

class CreateAuditEventsGoogleCloudLoggingConfigurations < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  UNIQUE_INDEX_NAME = "unique_google_cloud_logging_configurations_on_namespace_id"

  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    create_table :audit_events_google_cloud_logging_configurations do |t|
      t.references :namespace, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :google_project_id_name, null: false, limit: 30
      t.text :client_email, null: false, limit: 254
      t.text :log_id_name, default: "audit_events", limit: 511
      t.binary :encrypted_private_key, null: false
      t.binary :encrypted_private_key_iv, null: false

      t.index [:namespace_id, :google_project_id_name, :log_id_name], unique: true, name: UNIQUE_INDEX_NAME
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
