# frozen_string_literal: true

class AddPartitionedWebHookLogFk < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :web_hook_logs_part_0c5294f417,
      :web_hooks,
      column: :web_hook_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :web_hook_logs_part_0c5294f417, column: :web_hook_id
    end
  end
end
