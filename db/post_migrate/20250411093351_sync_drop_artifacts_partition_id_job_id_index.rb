# frozen_string_literal: true

class SyncDropArtifactsPartitionIdJobIdIndex < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.0'
  disable_ddl_transaction!

  INDEX_NAME = :p_ci_job_artifacts_partition_id_job_id_idx

  def up
    remove_concurrent_partitioned_index_by_name :p_ci_job_artifacts, INDEX_NAME
  end

  def down
    add_concurrent_partitioned_index :p_ci_job_artifacts, [:partition_id, :job_id], name: INDEX_NAME
  end
end
