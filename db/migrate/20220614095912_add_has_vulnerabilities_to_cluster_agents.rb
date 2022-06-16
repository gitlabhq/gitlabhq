# frozen_string_literal: true

class AddHasVulnerabilitiesToClusterAgents < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :cluster_agents, :has_vulnerabilities, :boolean, default: false, null: false
  end
end
