# frozen_string_literal: true

class RemoveUniqueIndexWithoutPartitionIdFromCiStages < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  TABLE_NAME = :ci_stages
  OLD_UNIQUE_INDEX_PIPELINE_ID_AND_NAME = :index_ci_stages_on_pipeline_id_and_name

  def up
    remove_concurrent_index_by_name(TABLE_NAME, OLD_UNIQUE_INDEX_PIPELINE_ID_AND_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, %i[pipeline_id name], unique: true, name: OLD_UNIQUE_INDEX_PIPELINE_ID_AND_NAME)
  end
end
