# frozen_string_literal: true

class AddPartitionedFkToProjectDailyStatisticsProjectIdWithReverseLockOrder < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_partitioned_foreign_key(
      :project_daily_statistics_b8088ecbd2,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :project_daily_statistics_b8088ecbd2,
        :projects,
        column: :project_id,
        reverse_lock_order: true
      )
    end
  end
end
