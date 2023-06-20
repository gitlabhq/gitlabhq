# frozen_string_literal: true

class AddAgentIdForeignKeyToEnvironments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :environments, :cluster_agents,
      column: :cluster_agent_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :environments, column: :cluster_agent_id
    end
  end
end
