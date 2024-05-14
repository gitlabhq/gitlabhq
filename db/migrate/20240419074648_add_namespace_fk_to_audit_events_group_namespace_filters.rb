# frozen_string_literal: true

class AddNamespaceFkToAuditEventsGroupNamespaceFilters < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :audit_events_streaming_group_namespace_filters,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :audit_events_streaming_group_namespace_filters,
        column: :namespace_id
    end
  end
end
