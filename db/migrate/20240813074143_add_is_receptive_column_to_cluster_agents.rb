# frozen_string_literal: true

class AddIsReceptiveColumnToClusterAgents < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :cluster_agents, :is_receptive, :bool, null: false, default: false
  end
end
