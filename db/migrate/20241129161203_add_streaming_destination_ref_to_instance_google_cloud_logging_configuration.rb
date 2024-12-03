# frozen_string_literal: true

class AddStreamingDestinationRefToInstanceGoogleCloudLoggingConfiguration < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  def up
    with_lock_retries do
      add_column :audit_events_instance_google_cloud_logging_configurations, :stream_destination_id, :bigint, null: true
    end
    add_concurrent_index :audit_events_instance_google_cloud_logging_configurations, :stream_destination_id,
      unique: true,
      name: "uniq_idx_audit_events_instance_gcp_configs_stream_dests",
      where: 'stream_destination_id IS NOT NULL'

    add_concurrent_foreign_key :audit_events_instance_google_cloud_logging_configurations,
      :audit_events_instance_external_streaming_destinations,
      column: :stream_destination_id,
      on_delete: :nullify
  end

  def down
    remove_concurrent_index_by_name :audit_events_instance_google_cloud_logging_configurations,
      "uniq_idx_audit_events_instance_gcp_configs_stream_dests"

    with_lock_retries do
      remove_foreign_key :audit_events_instance_google_cloud_logging_configurations,
        :audit_events_instance_external_streaming_destinations,
        column: :stream_destination_id
      remove_column :audit_events_instance_google_cloud_logging_configurations, :stream_destination_id
    end
  end
end
