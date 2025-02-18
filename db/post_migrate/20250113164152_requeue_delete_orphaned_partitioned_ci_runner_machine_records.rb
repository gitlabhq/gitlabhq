# frozen_string_literal: true

class RequeueDeleteOrphanedPartitionedCiRunnerMachineRecords < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "RequeueDeleteOrphanedPartitionedCiRunnerMachineRecords"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(MIGRATION, :ci_runner_machines_687967fa8a, :runner_id, [])

    queue_batched_background_migration(
      MIGRATION,
      :ci_runner_machines_687967fa8a,
      :runner_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runner_machines_687967fa8a, :runner_id, [])
  end
end
