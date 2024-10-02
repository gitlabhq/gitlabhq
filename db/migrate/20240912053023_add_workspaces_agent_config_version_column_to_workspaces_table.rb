# frozen_string_literal: true

class AddWorkspacesAgentConfigVersionColumnToWorkspacesTable < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :workspaces, :workspaces_agent_config_version, :integer
  end
end
