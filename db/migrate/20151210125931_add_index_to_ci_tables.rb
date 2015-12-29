class AddIndexToCiTables < ActiveRecord::Migration
  def change
    add_index :ci_builds, :gl_project_id
    add_index :ci_runner_projects, :gl_project_id
    add_index :ci_triggers, :gl_project_id
    add_index :ci_variables, :gl_project_id
    add_index :projects, :runners_token
    add_index :projects, :builds_enabled
    add_index :projects, [:builds_enabled, :shared_runners_enabled]
    add_index :projects, [:ci_id]
  end
end
