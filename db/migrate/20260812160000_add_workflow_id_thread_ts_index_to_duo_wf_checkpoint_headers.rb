# frozen_string_literal: true

class AddWorkflowIdThreadTsIndexToDuoWfCheckpointHeaders < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.3'

  TABLE_NAME = :p_duo_workflows_checkpoint_headers
  NEW_INDEX_NAME = 'index_duo_wf_checkpoint_headers_on_workflow_id_thread_ts_id'
  OLD_INDEX_NAME = 'index_duo_wf_checkpoint_headers_on_workflow_id'

  # Readers order a workflow's headers by thread_ts (the authoritative DWS
  # sequence), with id breaking ties between re-sends: the checkpoint list
  # endpoint, latest/first_checkpoint, and checkpoint_header_for. On workflow_id
  # alone each of those sorts the workflow's whole header set. `id` is included so
  # the index covers the full ordering. workflow_created_at is omitted: it is the
  # partition key, so it prunes rather than filters within a partition.
  COLUMNS = %i[workflow_id thread_ts id].freeze

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMNS, name: NEW_INDEX_NAME)
    # workflow_id is a leading prefix of the new index, which also serves the
    # foreign key's cascade delete.
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, :workflow_id, name: OLD_INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
