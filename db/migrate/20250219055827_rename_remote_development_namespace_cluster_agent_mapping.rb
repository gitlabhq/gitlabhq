# frozen_string_literal: true

class RenameRemoteDevelopmentNamespaceClusterAgentMapping < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    rename_table_safely(:remote_development_namespace_cluster_agent_mappings, :namespace_cluster_agent_mappings)
  end

  def down
    undo_rename_table_safely(:remote_development_namespace_cluster_agent_mappings, :namespace_cluster_agent_mappings)
  end
end
