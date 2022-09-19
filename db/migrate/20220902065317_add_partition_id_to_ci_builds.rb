# frozen_string_literal: true

class AddPartitionIdToCiBuilds < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddColumnsToWideTables
  def change
    add_column :ci_builds, :partition_id, :bigint, default: 100, null: false
  end
  # rubocop:enable Migration/AddColumnsToWideTables
end
