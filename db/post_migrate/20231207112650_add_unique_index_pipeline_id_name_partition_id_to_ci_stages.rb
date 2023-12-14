# frozen_string_literal: true

class AddUniqueIndexPipelineIdNamePartitionIdToCiStages < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  TABLE_NAME = :ci_stages
  UNIQUE_INDEX_PIPELINE_ID_AND_NAME = :index_ci_stages_on_pipeline_id_name_partition_id_unique

  def up
    add_concurrent_index(TABLE_NAME, %i[pipeline_id name partition_id], unique: true,
      name: UNIQUE_INDEX_PIPELINE_ID_AND_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, UNIQUE_INDEX_PIPELINE_ID_AND_NAME)
  end
end
