# frozen_string_literal: true

# This migration then deletes all ci_runner_machines_687967fa8a records
# that don't have a matching ci_runners_e59bb2812d record
class RequeueDeleteOrphanedPCiRunnerMachineRecordsOnDotCom < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "DeleteOrphanedPartitionedCiRunnerMachineRecords"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(MIGRATION, :ci_runner_machines_687967fa8a, :runner_id, [])

    return unless Gitlab.com_except_jh?

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
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :ci_runner_machines_687967fa8a, :runner_id, [])
  end
end
