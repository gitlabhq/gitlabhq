# frozen_string_literal: true

class AddUniqueIndexIdPartitionIdToCiJobArtifact < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!
  TABLE_NAME = :ci_job_artifacts
  INDEX_NAME = :index_ci_job_artifacts_on_id_partition_id_unique

  def up
    add_concurrent_index(TABLE_NAME, %i[id partition_id], unique: true, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
