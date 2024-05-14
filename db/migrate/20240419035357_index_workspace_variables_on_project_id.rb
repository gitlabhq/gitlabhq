# frozen_string_literal: true

class IndexWorkspaceVariablesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_workspace_variables_on_project_id'

  def up
    add_concurrent_index :workspace_variables, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :workspace_variables, INDEX_NAME
  end
end
