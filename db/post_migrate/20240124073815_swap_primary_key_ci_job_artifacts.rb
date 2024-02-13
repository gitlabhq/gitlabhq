# frozen_string_literal: true

class SwapPrimaryKeyCiJobArtifacts < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  disable_ddl_transaction!

  TABLE_NAME = :ci_job_artifacts
  PRIMARY_KEY = :ci_job_artifacts_pkey
  NEW_INDEX = :index_ci_job_artifacts_on_id_partition_id_unique
  OLD_INDEX = :index_ci_job_artifacts_on_id_unique

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY, NEW_INDEX)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY, OLD_INDEX)

    recreate_partitioned_foreign_keys
  end

  private

  def recreate_partitioned_foreign_keys
    add_partitioned_fk(:ci_build_trace_metadata, :fk_21d25cac1a_p, column: :trace_artifact_id)
    add_partitioned_fk(:ci_job_artifact_states, :fk_rails_80a9cba3b2_p, column: :job_artifact_id)
  end

  def add_partitioned_fk(source_table, name, column: nil)
    add_concurrent_foreign_key(
      source_table,
      TABLE_NAME,
      column: [:partition_id, column],
      target_column: [:partition_id, :id],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: name
    )
  end
end
