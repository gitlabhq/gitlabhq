# frozen_string_literal: true

class AddAsyncIndexesWithPartitionIdForCiPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  TABLE_NAME = :ci_pipeline_variables
  PK_INDEX_NAME = :index_ci_pipeline_variables_on_id_partition_id_unique
  UNIQUE_INDEX_NAME = :index_pipeline_variables_on_pipeline_id_key_partition_id_unique

  def up
    prepare_async_index TABLE_NAME, %i[id partition_id], name: PK_INDEX_NAME, unique: true
    prepare_async_index TABLE_NAME, %i[pipeline_id key partition_id], name: UNIQUE_INDEX_NAME, unique: true
  end

  def down
    unprepare_async_index TABLE_NAME, %i[id partition_id], name: PK_INDEX_NAME, unique: true
    unprepare_async_index TABLE_NAME, %i[pipeline_id key partition_id], name: UNIQUE_INDEX_NAME, unique: true
  end
end
