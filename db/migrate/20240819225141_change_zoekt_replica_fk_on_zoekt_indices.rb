# frozen_string_literal: true

class ChangeZoektReplicaFkOnZoektIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  NEW_CONSTRAINT_NAME = 'fk_zoekt_indices_on_zoekt_replica_id'

  def up
    add_concurrent_foreign_key(:zoekt_indices, :zoekt_replicas, column: :zoekt_replica_id, on_delete: :nullify,
      validate: false, name: NEW_CONSTRAINT_NAME)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:zoekt_indices, column: :zoekt_replica_id, on_delete: :nullify,
        name: NEW_CONSTRAINT_NAME)
    end
  end
end
