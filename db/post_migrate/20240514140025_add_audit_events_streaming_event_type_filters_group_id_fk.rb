# frozen_string_literal: true

class AddAuditEventsStreamingEventTypeFiltersGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :audit_events_streaming_event_type_filters, :namespaces, column: :group_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :audit_events_streaming_event_type_filters, column: :group_id
    end
  end
end
