# frozen_string_literal: true

class RemovePartitionPCiJobArtifactsProjectIdIdx < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.0'

  INDEX_NAME = :p_ci_job_artifacts_project_id_idx
  TABLE_NAME = :p_ci_job_artifacts

  def up
    unprepare_async_index_by_name(TABLE_NAME, INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end
end
