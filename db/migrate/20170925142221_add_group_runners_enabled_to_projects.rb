class AddGroupRunnersEnabledToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :projects, :group_runners_enabled, :boolean, default: true
    add_concurrent_index :projects, :group_runners_enabled
  end

  def down
    remove_column :projects, :group_runners_enabled
  end
end
