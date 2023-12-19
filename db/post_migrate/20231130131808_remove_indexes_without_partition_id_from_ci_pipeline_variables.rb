# frozen_string_literal: true

class RemoveIndexesWithoutPartitionIdFromCiPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_variables
  OLD_UNIQUE_INDEX_NAME = :index_ci_pipeline_variables_on_pipeline_id_and_key

  def up
    remove_concurrent_index_by_name(TABLE_NAME, OLD_UNIQUE_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, %i[pipeline_id key], unique: true, name: OLD_UNIQUE_INDEX_NAME)
  end
end
