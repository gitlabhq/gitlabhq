# frozen_string_literal: true

class AddKnowledgeGraphReplicasIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :p_knowledge_graph_replicas
  INDEX_NAME = :p_knowledge_graph_replicas_namespace_id_and_zoekt_node_id

  def up
    add_concurrent_partitioned_index TABLE_NAME,
      [:knowledge_graph_enabled_namespace_id, :zoekt_node_id, :namespace_id], unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
