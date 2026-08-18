# frozen_string_literal: true

class EnsureIdUniquenessForPDuoWorkflowsCheckpointHeaders < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '19.2'

  TABLE_NAME = :p_duo_workflows_checkpoint_headers
  SEQ_NAME = :p_duo_workflows_checkpoint_headers_id_seq

  # Headers are written via `bulk_insert!`, and on a partitioned table with a
  # composite [id, workflow_created_at] primary key the insert lists `id`
  # explicitly as NULL, so the column default never fires and the NOT NULL id
  # check fails. The BEFORE INSERT trigger assigns the id unconditionally,
  # mirroring the sibling p_duo_workflows_checkpoint_blobs.
  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
