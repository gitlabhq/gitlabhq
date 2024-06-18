# frozen_string_literal: true

class IndexAuditEventsStreamingEventTypeFiltersOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_audit_events_streaming_event_type_filters_on_group_id'

  def up
    add_concurrent_index :audit_events_streaming_event_type_filters, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :audit_events_streaming_event_type_filters, INDEX_NAME
  end
end
