# frozen_string_literal: true

class AddFkCdEnvironmentsToClusterAgents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_concurrent_foreign_key :cd_environments, :cluster_agents, column: :cluster_agent_id, on_delete: :restrict
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_environments, column: :cluster_agent_id
    end
  end
end
