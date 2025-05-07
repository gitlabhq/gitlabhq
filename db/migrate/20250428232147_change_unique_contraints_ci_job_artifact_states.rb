# frozen_string_literal: true

class ChangeUniqueContraintsCiJobArtifactStates < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  disable_ddl_transaction!

  TABLE_NAME = :ci_job_artifact_states
  PK_NAME = :ci_job_artifact_states_pkey
  OLD_INDEX_NAME = :index_ci_job_artifact_states_on_job_artifact_id_partition_id
  NEW_INDEX_NAME = :unique_ci_job_artifact_states_on_job_artifact_id_partition_id

  def up
    # Create a new concurrent unique index
    add_concurrent_index(TABLE_NAME, [:job_artifact_id, :partition_id], unique: true, name: NEW_INDEX_NAME)

    # Remove the existing non-unique index if it exists
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)

    # Now add the primary key using this unique index
    swap_primary_key(TABLE_NAME, PK_NAME, NEW_INDEX_NAME)
  end

  def down
    temp_index_name = :temp_ci_job_artifact_states_job_artifact_id_idx
    add_concurrent_index(TABLE_NAME, :job_artifact_id, unique: true, name: temp_index_name)

    # Swap the primary key to use this temporary index
    swap_primary_key(TABLE_NAME, PK_NAME, temp_index_name)

    # Create the original non-unique index for idempotency
    add_concurrent_index(TABLE_NAME, [:job_artifact_id, :partition_id], unique: false, name: OLD_INDEX_NAME)

    # Remove the composite unique index
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
