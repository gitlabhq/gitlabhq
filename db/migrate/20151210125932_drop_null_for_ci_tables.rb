class DropNullForCiTables < ActiveRecord::Migration
  def change
    remove_index :ci_variables, :project_id
    remove_index :ci_runner_projects, :project_id
    change_column_null :ci_triggers, :project_id, true
    change_column_null :ci_variables, :project_id, true
    change_column_null :ci_runner_projects, :project_id, true
  end
end
