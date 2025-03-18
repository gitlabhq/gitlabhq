# frozen_string_literal: true

class DeleteRemoteDevelopmentNamespaceClusterAgentMappingView < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    finalize_table_rename(:remote_development_namespace_cluster_agent_mappings, :namespace_cluster_agent_mappings)
  end

  def down
    undo_finalize_table_rename(:remote_development_namespace_cluster_agent_mappings, :namespace_cluster_agent_mappings)
  end
end
