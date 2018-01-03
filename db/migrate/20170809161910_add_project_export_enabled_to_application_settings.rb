class AddProjectExportEnabledToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:application_settings, :project_export_enabled, :boolean, default: true)
  end

  def down
    remove_column(:application_settings, :project_export_enabled)
  end
end
