# frozen_string_literal: true

class AddMaxResourcesPerWorkspaceToRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :remote_development_agent_configs, :max_resources_per_workspace, :jsonb, default: {}, null: false
  end
end
