# frozen_string_literal: true

class AddDefaultResourcesPerWorkspaceContainerToRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :remote_development_agent_configs, :default_resources_per_workspace_container, :jsonb, default: {},
      null: false
  end
end
