# frozen_string_literal: true

class RemoveFkWebHookLogsDailyGroupId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.10'
  disable_ddl_transaction!

  def up
    remove_partitioned_foreign_key :web_hook_logs_daily, column: :group_id, reverse_lock_order: true
  end

  def down
    add_concurrent_partitioned_foreign_key(
      :web_hook_logs_daily,
      :namespaces,
      column: :group_id,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end
end
