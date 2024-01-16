# frozen_string_literal: true

class AddFinishedAtIndexForPCiFinishedBuildChSyncEvents < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '16.8'

  INDEX_NAME = :index_p_ci_finished_build_ch_sync_events_finished_at
  TABLE_NAME = :p_ci_finished_build_ch_sync_events
  COLUMNS = [:partition, :build_finished_at]

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
