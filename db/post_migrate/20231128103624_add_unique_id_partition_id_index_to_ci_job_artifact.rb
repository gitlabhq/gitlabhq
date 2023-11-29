# frozen_string_literal: true

class AddUniqueIdPartitionIdIndexToCiJobArtifact < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  TABLE_NAME = :ci_job_artifacts
  INDEX_NAME = :index_ci_job_artifacts_on_id_partition_id_unique
  COLUMNS = %i[id partition_id]

  def up
    prepare_async_index(TABLE_NAME, COLUMNS, unique: true, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
