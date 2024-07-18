# frozen_string_literal: true

class AddIndexOnJobArtifactStateVerificationState < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  TABLE_NAME = :ci_job_artifact_states
  INDEX = 'index_on_job_artifact_id_partition_id_verification_state'
  COLUMNS = [:verification_state, :job_artifact_id, :partition_id]

  def up
    add_concurrent_index(
      TABLE_NAME,
      COLUMNS,
      name: INDEX
    )
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, name: INDEX)
  end
end
