class RenameGlProjectIdToProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Renaming an actively used column.'

  def change
    rename_column :ci_builds, :gl_project_id, :project_id
    rename_column :ci_commits, :gl_project_id, :project_id
    rename_column :ci_runner_projects, :gl_project_id, :project_id
    rename_column :ci_triggers, :gl_project_id, :project_id
    rename_column :ci_variables, :gl_project_id, :project_id
  end
end
