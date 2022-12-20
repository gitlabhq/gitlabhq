# frozen_string_literal: true

class AddPartitionIdToCiUnitTestFailures < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_unit_test_failures, :partition_id, :bigint, default: 100, null: false
  end
end
