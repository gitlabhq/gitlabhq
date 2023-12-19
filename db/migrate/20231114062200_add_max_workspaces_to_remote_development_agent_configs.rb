# frozen_string_literal: true

class AddMaxWorkspacesToRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :remote_development_agent_configs, :max_workspaces, :bigint, default: -1, null: false
  end
end
