# frozen_string_literal: true

class DropIndexWebHookLogsPartOnWebHookId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :index_web_hook_logs_part_on_web_hook_id
  TABLE_NAME = :web_hook_logs

  def up
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, :web_hook_id, name: INDEX_NAME)
  end
end
