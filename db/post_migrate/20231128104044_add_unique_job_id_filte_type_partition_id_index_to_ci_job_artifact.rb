# frozen_string_literal: true

class AddUniqueJobIdFilteTypePartitionIdIndexToCiJobArtifact < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  TABLE_NAME = :ci_job_artifacts
  INDEX_NAME = :idx_ci_job_artifacts_on_job_id_file_type_and_partition_id_uniq
  COLUMNS = %i[job_id file_type partition_id]

  def up
    prepare_async_index(TABLE_NAME, COLUMNS, unique: true, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
