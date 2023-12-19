# frozen_string_literal: true

class PrepareIndexesForPartitioningCiStages < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  TABLE_NAME = :ci_stages
  PK_INDEX_NAME = :index_ci_stages_on_id_partition_id_unique
  UNIQUE_INDEX_PIPELINE_ID_AND_NAME = :index_ci_stages_on_pipeline_id_name_partition_id_unique

  def up
    prepare_async_index TABLE_NAME, %i[id partition_id], name: PK_INDEX_NAME, unique: true
    prepare_async_index TABLE_NAME, %i[pipeline_id name partition_id], name: UNIQUE_INDEX_PIPELINE_ID_AND_NAME,
      unique: true
  end

  def down
    unprepare_async_index_by_name(TABLE_NAME, PK_INDEX_NAME)
    unprepare_async_index_by_name(TABLE_NAME, UNIQUE_INDEX_PIPELINE_ID_AND_NAME)
  end
end
