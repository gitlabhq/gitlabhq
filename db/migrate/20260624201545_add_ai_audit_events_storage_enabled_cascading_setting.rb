# frozen_string_literal: true

class AddAiAuditEventsStorageEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :ai_audit_events_storage_enabled, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :ai_audit_events_storage_enabled
  end
end
