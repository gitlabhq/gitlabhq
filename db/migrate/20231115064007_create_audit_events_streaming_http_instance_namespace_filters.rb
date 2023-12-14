# frozen_string_literal: true

class CreateAuditEventsStreamingHttpInstanceNamespaceFilters < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  UNIQ_DESTINATION_INDEX_NAME = 'unique_audit_events_instance_namespace_filters_destination_id'
  NAMESPACE_INDEX_NAME = 'index_audit_events_instance_namespace_filters_on_namespace_id'

  def change
    create_table :audit_events_streaming_http_instance_namespace_filters do |t|
      t.timestamps_with_timezone null: false
      t.bigint :audit_events_instance_external_audit_event_destination_id,
        null: false,
        index: { unique: true, name: UNIQ_DESTINATION_INDEX_NAME }
      t.bigint :namespace_id,
        null: false,
        index: { name: NAMESPACE_INDEX_NAME }
    end
  end
end
