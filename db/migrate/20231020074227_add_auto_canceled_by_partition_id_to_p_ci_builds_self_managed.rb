# frozen_string_literal: true

class AddAutoCanceledByPartitionIdToPCiBuildsSelfManaged < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  # rubocop:disable Migration/AddColumnsToWideTables -- partitioning ci_builds table
  def up
    add_column :p_ci_builds, :auto_canceled_by_partition_id, :bigint, default: 100, null: false, if_not_exists: true
  end
  # rubocop:enable Migration/AddColumnsToWideTables

  def down
    remove_column :p_ci_builds, :auto_canceled_by_partition_id, if_exists: true
  end
end
