# frozen_string_literal: true

class CreateZoektIndicesReplicaIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  INDEX_NAME = 'index_zoekt_indices_on_replica_id'

  def up
    add_concurrent_index :zoekt_indices, :zoekt_replica_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_indices, INDEX_NAME
  end
end
