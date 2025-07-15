# frozen_string_literal: true

class AddReplicaReservedStorageBytes < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  DEFAULT_SIZE = 10 * 1024 * 1024

  def change
    add_column :p_knowledge_graph_replicas, :reserved_storage_bytes, :bigint, default: DEFAULT_SIZE, null: false
  end
end
