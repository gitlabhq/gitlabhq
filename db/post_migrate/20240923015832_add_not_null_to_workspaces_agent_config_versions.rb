# frozen_string_literal: true

class AddNotNullToWorkspacesAgentConfigVersions < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    change_column :workspaces, :workspaces_agent_config_version, :integer, null: false
  end

  def down
    change_column :workspaces, :workspaces_agent_config_version, :integer, null: true
  end
end
