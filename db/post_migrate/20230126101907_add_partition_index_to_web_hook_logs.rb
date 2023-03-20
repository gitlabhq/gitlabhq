# frozen_string_literal: true

class AddPartitionIndexToWebHookLogs < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_web_hook_logs_on_web_hook_id_and_created_at'

  def up
    add_concurrent_partitioned_index(
      :web_hook_logs,
      [:web_hook_id, :created_at],
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name :web_hook_logs, INDEX_NAME
  end
end
