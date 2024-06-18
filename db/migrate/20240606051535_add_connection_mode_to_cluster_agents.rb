# frozen_string_literal: true

class AddConnectionModeToClusterAgents < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :cluster_agents, :connection_mode, :smallint, null: false, default: 0
  end
end
