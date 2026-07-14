# frozen_string_literal: true

class AddAiAuditEventsStorageEnabledToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :project_settings, :ai_audit_events_storage_enabled, :boolean, default: false, null: false
  end
end
