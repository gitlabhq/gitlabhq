# frozen_string_literal: true

class CreateInstanceGoogleCloudLoggingConfigurations < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  UNIQUE_INDEX_NAME = "unique_instance_google_cloud_logging_configurations"
  UNIQUE_CONFIG_NAME_INDEX = "unique_instance_google_cloud_logging_configurations_name"

  def change
    create_table :audit_events_instance_google_cloud_logging_configurations do |t|
      t.timestamps_with_timezone null: false
      t.text :google_project_id_name, null: false, limit: 30
      t.text :client_email, null: false, limit: 254
      t.text :log_id_name, default: "audit_events", limit: 511
      t.text :name, null: false, limit: 72
      t.binary :encrypted_private_key, null: false
      t.binary :encrypted_private_key_iv, null: false

      t.index [:google_project_id_name, :log_id_name], unique: true, name: UNIQUE_INDEX_NAME
      t.index :name, unique: true, name: UNIQUE_CONFIG_NAME_INDEX
    end
  end
end
