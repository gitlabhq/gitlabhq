class AddIndexToProjectIdOnProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_registry, :project_id
  end

  def down
    remove_index :project_registry, :project_id
  end
end
