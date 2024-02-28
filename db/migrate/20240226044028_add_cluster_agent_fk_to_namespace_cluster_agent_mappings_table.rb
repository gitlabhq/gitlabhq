# frozen_string_literal: true

class AddClusterAgentFkToNamespaceClusterAgentMappingsTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  def up
    add_concurrent_foreign_key :remote_development_namespace_cluster_agent_mappings,
      :cluster_agents,
      column: :cluster_agent_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :remote_development_namespace_cluster_agent_mappings, column: :cluster_agent_id
    end
  end
end
