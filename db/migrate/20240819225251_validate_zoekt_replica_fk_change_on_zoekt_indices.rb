# frozen_string_literal: true

class ValidateZoektReplicaFkChangeOnZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  NEW_CONSTRAINT_NAME = ChangeZoektReplicaFkOnZoektIndices::NEW_CONSTRAINT_NAME

  # foreign key added in ChangeZoektReplicaFKOnZoektIndices migration
  def up
    validate_foreign_key(:zoekt_indices, :zoekt_replica_id, name: NEW_CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
