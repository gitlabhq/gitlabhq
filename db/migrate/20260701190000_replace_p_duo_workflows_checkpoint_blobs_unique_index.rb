# frozen_string_literal: true

class ReplacePDuoWorkflowsCheckpointBlobsUniqueIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :p_duo_workflows_checkpoint_blobs
  OLD_INDEX_NAME = 'idx_duo_wf_checkpoint_blobs_unique'
  NEW_INDEX_NAME = 'idx_duo_wf_checkpoint_blobs_dedup'

  # step_action distinguishes a `conversation` (tail delta) from a `compaction`
  # (full value) that can legitimately share the same (channel, version); keying
  # dedup on it prevents a redundant re-send from collapsing the two into one
  # representation. created_at is required because a partitioned table's unique
  # index must include the partition key. See
  # https://gitlab.com/gitlab-org/gitlab/-/issues/604371.
  NEW_COLUMNS = %i[project_id workflow_id thread_ts channel version step_action created_at].freeze
  OLD_COLUMNS = %i[project_id workflow_id thread_ts channel version created_at].freeze

  def up
    add_concurrent_partitioned_index(
      TABLE_NAME, NEW_COLUMNS, unique: true, nulls_not_distinct: true, name: NEW_INDEX_NAME
    )
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(
      TABLE_NAME, OLD_COLUMNS, unique: true, nulls_not_distinct: true, name: OLD_INDEX_NAME
    )
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
