# frozen_string_literal: true

class RemovePartitionIdDefaultValueForCiPipelineMessage < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :ci_pipeline_messages
  COLUM_NAME = :partition_id

  def change
    change_column_default(TABLE_NAME, COLUM_NAME, from: 100, to: nil)
  end
end
