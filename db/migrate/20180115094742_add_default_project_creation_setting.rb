class AddDefaultProjectCreationSetting < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :default_project_creation, :integer, default: 2)
  end

  def down
    remove_column(:application_settings, :default_project_creation)
  end
end
