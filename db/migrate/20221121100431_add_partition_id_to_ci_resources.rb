# frozen_string_literal: true

class AddPartitionIdToCiResources < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column(:ci_resources, :partition_id, :bigint, default: 100, null: false)
  end
end
