# frozen_string_literal: true

class QueueBackfillPartitionIdCiPipelineMessage < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillPartitionIdCiPipelineMessage"
  DELAY_INTERVAL = 2.minutes
  GITLAB_OPTIMIZED_BATCH_SIZE = 75_000
  GITLAB_OPTIMIZED_SUB_BATCH_SIZE = 750
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_pipeline_messages,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: batch_sizes[:batch_size],
      sub_batch_size: batch_sizes[:sub_batch_size]
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_pipeline_messages, :id, [])
  end

  private

  def batch_sizes
    if Gitlab.com_except_jh?
      {
        batch_size: GITLAB_OPTIMIZED_BATCH_SIZE,
        sub_batch_size: GITLAB_OPTIMIZED_SUB_BATCH_SIZE
      }
    else
      {
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE
      }
    end
  end
end
