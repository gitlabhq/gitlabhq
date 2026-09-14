# frozen_string_literal: true

class SwapWorkflowIdIndexOnPDuoWorkflowsCheckpointBlobs < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = :p_duo_workflows_checkpoint_blobs
  COLUMNS = %i[workflow_id channel id].freeze
  INDEX_NAME = 'idx_duo_wf_checkpoint_blobs_on_workflow_channel_id'
  OLD_COLUMNS = %i[workflow_id].freeze
  OLD_INDEX_NAME = 'index_duo_wf_checkpoint_blobs_on_workflow_id'

  # The per-partition indexes are built asynchronously
  # (20260831075300_prepare_idx_duo_wf_checkpoint_blobs_on_workflow_channel_id),
  # so on GitLab.com this only attaches them. The old (workflow_id) index is
  # redundant: workflow_id leads the new index.
  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, OLD_COLUMNS, name: OLD_INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
