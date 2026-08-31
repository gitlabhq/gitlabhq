# frozen_string_literal: true

class PrepareIdxDuoWfCheckpointBlobsOnWorkflowChannelId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.4'

  TABLE_NAME = :p_duo_workflows_checkpoint_blobs
  COLUMNS = %i[workflow_id channel id].freeze
  INDEX_NAME = 'idx_duo_wf_checkpoint_blobs_on_workflow_channel_id'

  def up
    prepare_partitioned_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    # _by_name: the other form reads its second argument as column names.
    unprepare_partitioned_async_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
