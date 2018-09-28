class AddPartialIndexToProjectsForLastRepositoryCheckAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = "index_projects_on_last_repository_check_at"

  def up
    add_concurrent_index(:projects, :last_repository_check_at, where: "last_repository_check_at IS NOT NULL", name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:projects, :last_repository_check_at, where: "last_repository_check_at IS NOT NULL", name: INDEX_NAME)
  end
end
