# frozen_string_literal: true

class AddIndexForCiFinishedPipelineChSyncEventOnProjectNamespaceId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.4'

  TABLE_NAME = :p_ci_finished_pipeline_ch_sync_events
  INDEX_NAME = 'idx_p_ci_finished_pipeline_ch_sync_evts_on_project_namespace_id'

  def up
    add_concurrent_partitioned_index TABLE_NAME, :project_namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
