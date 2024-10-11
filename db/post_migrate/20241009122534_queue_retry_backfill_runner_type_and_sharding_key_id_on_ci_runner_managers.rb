# frozen_string_literal: true

class QueueRetryBackfillRunnerTypeAndShardingKeyIdOnCiRunnerManagers < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillRunnerTypeAndShardingKeyIdOnCiRunnerManagers'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # Delete aborted 20241003110148 migration in .com
    delete_batched_background_migration(MIGRATION, :ci_runner_machines, :id, []) if Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :ci_runner_machines,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runner_machines, :id, [])
  end
end
