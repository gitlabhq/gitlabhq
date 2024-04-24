# frozen_string_literal: true

class AddWorkspaceVariablesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    install_sharding_key_assignment_trigger(
      table: :workspace_variables,
      sharding_key: :project_id,
      parent_table: :workspaces,
      parent_sharding_key: :project_id,
      foreign_key: :workspace_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :workspace_variables,
      sharding_key: :project_id,
      parent_table: :workspaces,
      parent_sharding_key: :project_id,
      foreign_key: :workspace_id
    )
  end
end
