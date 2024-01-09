# frozen_string_literal: true

class RemovePartitionIdDefaultValueForCiPipelineChatData < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  TABLE_NAME = :ci_pipeline_chat_data
  COLUM_NAME = :partition_id

  def change
    change_column_default(TABLE_NAME, COLUM_NAME, from: 100, to: nil)
  end
end
