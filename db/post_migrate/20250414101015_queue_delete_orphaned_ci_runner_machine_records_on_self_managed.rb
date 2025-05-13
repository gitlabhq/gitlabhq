# frozen_string_literal: true

class QueueDeleteOrphanedCiRunnerMachineRecordsOnSelfManaged < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '18.0'

  MIGRATION = 'DeleteOrphanedCiRunnerMachineRecordsOnSelfManaged'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    return if Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :ci_runner_machines,
      :runner_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return if Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :ci_runner_machines, :runner_id, [])
  end
end
