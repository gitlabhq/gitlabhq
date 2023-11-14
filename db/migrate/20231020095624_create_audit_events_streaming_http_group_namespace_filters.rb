# frozen_string_literal: true

class CreateAuditEventsStreamingHttpGroupNamespaceFilters < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  UNIQ_DESTINATION_INDEX_NAME = 'unique_audit_events_group_namespace_filters_destination_id'
  UNIQ_NAMESPACE_INDEX_NAME = 'unique_audit_events_group_namespace_filters_namespace_id'

  def change
    create_table :audit_events_streaming_http_group_namespace_filters do |t|
      t.timestamps_with_timezone null: false
      t.references :external_audit_event_destination,
        null: false,
        index: { unique: true, name: UNIQ_DESTINATION_INDEX_NAME },
        foreign_key: { to_table: 'audit_events_external_audit_event_destinations', on_delete: :cascade }
      t.references :namespace,
        null: false,
        index: { unique: true, name: UNIQ_NAMESPACE_INDEX_NAME },
        foreign_key: { on_delete: :cascade }
    end
  end
end
