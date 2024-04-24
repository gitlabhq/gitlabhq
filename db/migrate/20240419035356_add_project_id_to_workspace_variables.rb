# frozen_string_literal: true

class AddProjectIdToWorkspaceVariables < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :workspace_variables, :project_id, :bigint
  end
end
