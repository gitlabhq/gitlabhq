# frozen_string_literal: true

class IndexFinishedPipelineSyncEventsOnPipelineId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :p_ci_finished_pipeline_ch_sync_events
  INDEX_NAME = 'index_p_ci_finished_pipeline_ch_sync_events_on_pipeline_id'

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME,
      :pipeline_id,
      name: INDEX_NAME,
      where: 'processed = FALSE'
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
