# frozen_string_literal: true

class QueueBackfillPCiRunnerMachineBuildsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillPCiRunnerMachineBuildsProjectId"
  TABLE_NAME = :p_ci_runner_machine_builds
  BATCH_COLUMN = :build_id
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25_000
  SUB_BATCH_SIZE = 150
  JOB_ARGS = %i[project_id p_ci_builds project_id build_id partition_id]

  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      *JOB_ARGS,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)
  end
end
