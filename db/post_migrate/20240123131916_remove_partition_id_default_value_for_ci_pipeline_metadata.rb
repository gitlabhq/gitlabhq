# frozen_string_literal: true

class RemovePartitionIdDefaultValueForCiPipelineMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  enable_lock_retries!

  TABLE_NAME = :ci_pipeline_metadata
  COLUM_NAME = :partition_id

  def change
    change_column_default(TABLE_NAME, COLUM_NAME, from: 100, to: nil)
  end
end
