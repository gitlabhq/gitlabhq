# frozen_string_literal: true

class AddIndexOnWebHookIdToPartitionedWebHookLog < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  WEB_HOOK_ID_INDEX_NAME = 'index_web_hook_logs_part_on_web_hook_id'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_index :web_hook_logs_part_0c5294f417,
      :web_hook_id,
      name: WEB_HOOK_ID_INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :web_hook_logs_part_0c5294f417, WEB_HOOK_ID_INDEX_NAME
  end
end
