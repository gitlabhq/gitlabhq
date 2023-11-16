# frozen_string_literal: true

class AddMaxWorkspacesPerUserToRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :remote_development_agent_configs, :max_workspaces_per_user, :bigint, default: -1, null: false
  end
end
