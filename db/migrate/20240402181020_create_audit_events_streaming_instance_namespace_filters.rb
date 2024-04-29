# frozen_string_literal: true

class CreateAuditEventsStreamingInstanceNamespaceFilters < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  enable_lock_retries!

  UNIQ_INDEX_NAME = 'uniq_idx_streaming_destination_id_and_namespace_id'
  NAMESPACE_INDEX_NAME = 'idx_streaming_instance_namespace_filters_on_namespace_id'

  def change
    create_table :audit_events_streaming_instance_namespace_filters do |t|
      t.timestamps_with_timezone null: false
      t.bigint :external_streaming_destination_id,
        null: false
      t.bigint :namespace_id,
        null: false,
        index: { name: NAMESPACE_INDEX_NAME }
      t.index [:external_streaming_destination_id, :namespace_id], unique: true, name: UNIQ_INDEX_NAME
    end
  end
end
