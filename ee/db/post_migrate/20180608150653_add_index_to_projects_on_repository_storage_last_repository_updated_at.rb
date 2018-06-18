class AddIndexToProjectsOnRepositoryStorageLastRepositoryUpdatedAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_projects_on_repository_storage_last_repository_updated_at'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :projects,
      [:id, :repository_storage, :last_repository_updated_at],
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:projects, INDEX_NAME)
  end
end
