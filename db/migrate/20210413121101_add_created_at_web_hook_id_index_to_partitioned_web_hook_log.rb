# frozen_string_literal: true

class AddCreatedAtWebHookIdIndexToPartitionedWebHookLog < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  CREATED_AT_WEB_HOOK_ID_INDEX_NAME = 'index_web_hook_logs_part_on_created_at_and_web_hook_id'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_index :web_hook_logs_part_0c5294f417,
      [:created_at, :web_hook_id],
      name: CREATED_AT_WEB_HOOK_ID_INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :web_hook_logs_part_0c5294f417, CREATED_AT_WEB_HOOK_ID_INDEX_NAME
  end
end
