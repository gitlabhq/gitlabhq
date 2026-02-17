# frozen_string_literal: true

class AddIndexWebHookLogsDailyOnProjectId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_web_hook_logs_daily_on_project_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- required for sharding
    add_concurrent_partitioned_index :web_hook_logs_daily, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_partitioned_index_by_name :web_hook_logs_daily, INDEX_NAME
  end
end
