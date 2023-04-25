# frozen_string_literal: true

class AddCiRunnerProjectIndexToRunnerIdAndProjectId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_ci_runner_projects_on_runner_id'
  NEW_INDEX_NAME = 'index_ci_runner_projects_on_runner_id_and_project_id'
  TABLE_NAME = :ci_runner_projects

  def up
    add_concurrent_index(TABLE_NAME, [:runner_id, :project_id], name: NEW_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :runner_id, name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
