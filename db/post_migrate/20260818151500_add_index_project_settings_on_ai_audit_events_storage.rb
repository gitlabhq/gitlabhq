# frozen_string_literal: true

class AddIndexProjectSettingsOnAiAuditEventsStorage < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  INDEX_NAME = 'idx_project_settings_on_project_id_where_ai_audit_storage'

  def up
    add_concurrent_index :project_settings, :project_id,
      where: 'ai_audit_events_storage_enabled = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_settings, INDEX_NAME
  end
end
