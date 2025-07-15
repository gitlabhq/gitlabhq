# frozen_string_literal: true

class ChangeKnowledgeGraphReplicaNamespaceIndex < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  INDEX_NAME = 'index_p_knowledge_graph_replicas_on_namespace_id'

  # rubocop:disable Migration/AddIndex, Migration/RemoveIndex -- these are on empty tables
  def up
    # index with the same name is re-created, but without "unique: true"
    remove_index :p_knowledge_graph_replicas, name: INDEX_NAME
    add_index :p_knowledge_graph_replicas, :namespace_id, name: INDEX_NAME
  end

  def down
    # on rollback we intentionally keep not-unique index, there can be some not-unique records
  end
  # rubocop:enable Migration/AddIndex, Migration/RemoveIndex
end
