# frozen_string_literal: true

class AddFkWebHookLogsDailyOrganizationId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.9'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key(
      :web_hook_logs_daily,
      :organizations,
      column: :organization_id,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end

  def down
    remove_partitioned_foreign_key :web_hook_logs_daily, column: :organization_id, reverse_lock_order: true
  end
end
