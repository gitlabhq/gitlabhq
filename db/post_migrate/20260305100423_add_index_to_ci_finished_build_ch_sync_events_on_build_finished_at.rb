# frozen_string_literal: true

class AddIndexToCiFinishedBuildChSyncEventsOnBuildFinishedAt < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.10'

  INDEX_NAME = 'index_ci_finished_build_ch_sync_events_on_mode_filter'
  TABLE_NAME = :p_ci_finished_build_ch_sync_events

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME,
      '((build_id % 100)), build_finished_at, build_id',
      where: 'processed = false',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
