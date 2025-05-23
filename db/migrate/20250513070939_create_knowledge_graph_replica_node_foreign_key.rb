# frozen_string_literal: true

class CreateKnowledgeGraphReplicaNodeForeignKey < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_partitioned_foreign_key :p_knowledge_graph_replicas, :zoekt_nodes,
      column: :zoekt_node_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :p_knowledge_graph_replicas, column: :zoekt_node_id
    end
  end
end
