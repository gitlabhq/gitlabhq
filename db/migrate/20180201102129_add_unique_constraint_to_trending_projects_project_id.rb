class AddUniqueConstraintToTrendingProjectsProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :trending_projects, :project_id, unique: true, name: 'index_trending_projects_on_project_id_unique'
    remove_concurrent_index_by_name :trending_projects, 'index_trending_projects_on_project_id'
    rename_index :trending_projects, 'index_trending_projects_on_project_id_unique', 'index_trending_projects_on_project_id'
  end

  def down
    rename_index :trending_projects, 'index_trending_projects_on_project_id', 'index_trending_projects_on_project_id_old'
    add_concurrent_index :trending_projects, :project_id
    remove_concurrent_index_by_name :trending_projects, 'index_trending_projects_on_project_id_old'
  end
end
