# frozen_string_literal: true

class AddZoektReplicaToZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :zoekt_indices, :zoekt_replicas,
      column: :zoekt_replica_id, on_delete: :cascade, reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_indices, column: :zoekt_replica_id
    end
  end
end
