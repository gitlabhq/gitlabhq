# frozen_string_literal: true

class QueueBackfillDuoWorkflowsCheckpointHeadersAndBlobs < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillDuoWorkflowsCheckpointHeadersAndBlobs"
  TABLE_NAME = :p_duo_workflows_checkpoints
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  # A sub-batch is held in memory twice (decoded rows, then header and blob
  # attributes). On GitLab.com a checkpoint is 2.4 MB raw at p99 and up to 6 MB.
  SUB_BATCH_SIZE = 10

  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE_NAME, :id, [])
  end
end
