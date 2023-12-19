# frozen_string_literal: true

class AddNamespaceFkToAuditEventsHttpInstanceNamespaceFilters < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :audit_events_streaming_http_instance_namespace_filters,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :audit_events_streaming_http_instance_namespace_filters,
        column: :namespace_id
    end
  end
end
