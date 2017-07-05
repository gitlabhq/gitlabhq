class AddIndexToProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_registry, :last_repository_synced_at
    add_concurrent_index :project_registry, :last_repository_successful_sync_at
    add_concurrent_index :project_registry, :resync_repository
    add_concurrent_index :project_registry, :resync_wiki
  end

  def down
    remove_concurrent_index :project_registry, :last_repository_synced_at if index_exists?(:project_registry, :last_repository_synced_at)
    remove_concurrent_index :project_registry, :last_repository_successful_sync_at if index_exists?(:project_registry, :last_repository_successful_sync_at)
    remove_concurrent_index :project_registry, :resync_repository if index_exists?(:project_registry, :resync_repository)
    remove_concurrent_index :project_registry, :resync_wiki if index_exists?(:project_registry, :resync_wiki)
  end
end
