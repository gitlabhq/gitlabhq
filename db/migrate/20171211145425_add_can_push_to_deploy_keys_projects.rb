class AddCanPushToDeployKeysProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column_with_default :deploy_keys_projects, :can_push, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :deploy_keys_projects, :can_push
  end
end
