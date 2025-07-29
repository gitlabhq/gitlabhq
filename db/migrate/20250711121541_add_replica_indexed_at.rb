# frozen_string_literal: true

class AddReplicaIndexedAt < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :p_knowledge_graph_replicas, :indexed_at, :datetime_with_timezone
    add_column :p_knowledge_graph_replicas, :schema_version, :smallint, null: false, default: 0

    # rubocop:disable Migration/AddIndex -- replica table is empty
    add_index :p_knowledge_graph_replicas, :schema_version
    # rubocop:enable Migration/AddIndex
  end
end
