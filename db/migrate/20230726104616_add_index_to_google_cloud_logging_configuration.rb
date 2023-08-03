# frozen_string_literal: true

class AddIndexToGoogleCloudLoggingConfiguration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'uniq_google_cloud_logging_configuration_namespace_id_and_name'

  def up
    add_concurrent_index :audit_events_google_cloud_logging_configurations, [:namespace_id, :name], unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :audit_events_google_cloud_logging_configurations, INDEX_NAME
  end
end
