# frozen_string_literal: true

class PrepareAsyncIndexWebHookLogsDailyOnOrganizationId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.8'
  disable_ddl_transaction!

  PARTITIONED_INDEX_NAME = 'index_web_hook_logs_daily_on_organization_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- required for sharding
    prepare_partitioned_async_index :web_hook_logs_daily, :organization_id, name: PARTITIONED_INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_partitioned_async_index :web_hook_logs_daily, PARTITIONED_INDEX_NAME
  end
end
