# frozen_string_literal: true

class AddIndexNamespaceSettingsOnAiAuditEventsStorage < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  INDEX_NAME = 'idx_namespace_settings_on_ns_id_where_ai_audit_storage_enabled'

  def up
    add_concurrent_index :namespace_settings, :namespace_id,
      where: 'ai_audit_events_storage_enabled = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespace_settings, INDEX_NAME
  end
end
