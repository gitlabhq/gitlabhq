# frozen_string_literal: true

class AddIndexesToWebHookLogsDaily < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.9'
  disable_ddl_transaction!

  TABLE_NAME = :web_hook_logs_daily
  INDEX_NAME_1 = :index_web_hook_logs_daily_on_web_hook_id_and_created_at
  INDEX_NAME_2 = :index_web_hook_logs_daily_part_on_created_at_and_web_hook_id
  COLUMN_NAMES_1 = [:web_hook_id, :created_at]
  COLUMN_NAMES_2 = [:created_at, :web_hook_id]

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES_1, name: INDEX_NAME_1)
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES_2, name: INDEX_NAME_2)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME_1)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME_2)
  end
end
