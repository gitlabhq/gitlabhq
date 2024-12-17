# frozen_string_literal: true

class AddAutoCanceledByPartitionIdToPCiBuildsSelfManaged < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    # rubocop:disable Migration/PreventAddingColumns -- partitioning ci_builds table
    add_column :p_ci_builds, :auto_canceled_by_partition_id, :bigint, default: 100, null: false, if_not_exists: true
    # rubocop:enable Migration/PreventAddingColumns
  end

  def down
    remove_column :p_ci_builds, :auto_canceled_by_partition_id, if_exists: true
  end
end
