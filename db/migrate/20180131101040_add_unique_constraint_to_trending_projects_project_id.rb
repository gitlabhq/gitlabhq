class AddUniqueConstraintToTrendingProjectsProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # Don't drop-and-create index so we don't have a gap
  # Instead:
  # 1) Add new index with temporary name
  # 2) Drop old index
  # 3) Rename new index back to original name

  def up
    add_concurrent_index :trending_projects, :project_id, unique: true, name: temp_index_name

    remove_foreign_key :trending_projects, :projects
    remove_concurrent_index :trending_projects, :project_id, name: actual_index_name
    add_concurrent_foreign_key :trending_projects, :projects, column: :project_id, on_delete: :cascade

    rename_index :trending_projects, temp_index_name, actual_index_name
  end

  def down
    add_concurrent_index :trending_projects, :project_id, name: temp_index_name

    remove_foreign_key :trending_projects, :projects
    remove_concurrent_index :trending_projects, :project_id, name: actual_index_name
    add_concurrent_foreign_key :trending_projects, :projects, column: :project_id, on_delete: :cascade

    rename_index :trending_projects, temp_index_name, actual_index_name
  end

  private

  def temp_index_name
    'index_trending_projects_on_project_id_new'
  end

  def actual_index_name
    'index_trending_projects_on_project_id'
  end
end
