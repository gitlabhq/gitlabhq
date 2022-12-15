# frozen_string_literal: true

class ChangeDefaultPartitionIdOnCiResources < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    change_column_default :ci_resources, :partition_id, from: 100, to: nil
  end
end
