# frozen_string_literal: true

class AddAuditEventsEnabledToNamespacePackageSettings < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    add_column :namespace_package_settings, :audit_events_enabled, :boolean, default: false, null: false,
      if_not_exists: true
  end

  def down
    remove_column :namespace_package_settings, :audit_events_enabled, if_exists: true
  end
end
