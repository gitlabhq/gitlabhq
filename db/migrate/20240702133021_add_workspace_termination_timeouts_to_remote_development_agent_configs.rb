# frozen_string_literal: true

class AddWorkspaceTerminationTimeoutsToRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :remote_development_agent_configs, :default_max_hours_before_termination, :smallint, default: 24,
      null: false
    add_column :remote_development_agent_configs, :max_hours_before_termination_limit, :smallint, default: 120,
      null: false
  end
end
