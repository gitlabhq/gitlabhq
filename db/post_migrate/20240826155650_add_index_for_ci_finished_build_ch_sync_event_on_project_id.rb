# frozen_string_literal: true

class AddIndexForCiFinishedBuildChSyncEventOnProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '17.4'

  TABLE_NAME = :p_ci_finished_build_ch_sync_events
  INDEX_NAME = :index_p_ci_finished_build_ch_sync_events_on_project_id
  COLUMN = :project_id

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
