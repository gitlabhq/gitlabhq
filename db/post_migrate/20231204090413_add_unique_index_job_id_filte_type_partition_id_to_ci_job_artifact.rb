# frozen_string_literal: true

class AddUniqueIndexJobIdFilteTypePartitionIdToCiJobArtifact < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!
  TABLE_NAME = :ci_job_artifacts
  INDEX_NAME = :idx_ci_job_artifacts_on_job_id_file_type_and_partition_id_uniq

  def up
    add_concurrent_index(TABLE_NAME, %i[job_id file_type partition_id], unique: true, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
