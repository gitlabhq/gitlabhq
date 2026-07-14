# frozen_string_literal: true

class AddWorkflowForeignKeyToPDuoWorkflowsCheckpointBlobs < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '19.2'

  SOURCE_TABLE_NAME = :p_duo_workflows_checkpoint_blobs
  TARGET_TABLE_NAME = :duo_workflows_workflows
  COLUMN = :workflow_id
  FK_NAME = :fk_duo_wf_checkpoint_blobs_workflow_id

  # workflow_id references the (small) duo_workflows_workflows table, so a strict
  # partitioned FK is viable and gives immediate cascade cleanup when a workflow
  # is deleted, mirroring p_duo_workflows_checkpoints. The project_id/namespace_id
  # sharding keys intentionally have no FK (cleanup relies on the 30-day partition
  # drop) because a partitioned FK to projects/namespaces is infeasible on .com.
  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: COLUMN,
      name: FK_NAME,
      on_delete: :cascade
    )
  end

  def down
    remove_partitioned_foreign_key(SOURCE_TABLE_NAME, TARGET_TABLE_NAME, name: FK_NAME)
  end
end
