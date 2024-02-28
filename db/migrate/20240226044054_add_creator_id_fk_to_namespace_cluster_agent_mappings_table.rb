# frozen_string_literal: true

class AddCreatorIdFkToNamespaceClusterAgentMappingsTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  def up
    add_concurrent_foreign_key :remote_development_namespace_cluster_agent_mappings,
      :users,
      column: :creator_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :remote_development_namespace_cluster_agent_mappings, column: :creator_id
    end
  end
end
