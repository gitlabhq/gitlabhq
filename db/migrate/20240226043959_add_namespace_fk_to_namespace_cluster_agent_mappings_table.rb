# frozen_string_literal: true

class AddNamespaceFkToNamespaceClusterAgentMappingsTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  def up
    add_concurrent_foreign_key :remote_development_namespace_cluster_agent_mappings,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :remote_development_namespace_cluster_agent_mappings, column: :namespace_id
    end
  end
end
