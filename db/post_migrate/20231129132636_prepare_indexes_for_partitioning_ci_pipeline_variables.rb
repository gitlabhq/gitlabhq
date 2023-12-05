# frozen_string_literal: true

class PrepareIndexesForPartitioningCiPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_variables
  PK_INDEX_NAME = :index_ci_pipeline_variables_on_id_partition_id_unique
  UNIQUE_INDEX_NAME = :index_pipeline_variables_on_pipeline_id_key_partition_id_unique

  def up
    add_concurrent_index(TABLE_NAME, %i[id partition_id], unique: true, name: PK_INDEX_NAME)
    add_concurrent_index(TABLE_NAME, %i[pipeline_id key partition_id], unique: true, name: UNIQUE_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, PK_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, UNIQUE_INDEX_NAME)
  end
end
