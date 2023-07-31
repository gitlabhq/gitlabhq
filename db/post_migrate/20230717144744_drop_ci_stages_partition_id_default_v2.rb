# frozen_string_literal: true

class DropCiStagesPartitionIdDefaultV2 < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  TABLE_NAME = :ci_stages
  COLUMN_NAME = :partition_id

  def up
    remove_column_default(TABLE_NAME, COLUMN_NAME)
  end

  def down
    change_column_default(TABLE_NAME, COLUMN_NAME, from: nil, to: 100)
  end
end
