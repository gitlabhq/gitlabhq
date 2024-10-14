# frozen_string_literal: true

# rubocop:disable BackgroundMigration/DictionaryFile -- There is no corresponding BBM dictionary,
# as the original BBM is still in place.
class RequeueBackfillPCiRunnerMachineBuildsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillPCiRunnerMachineBuildsProjectId"
  TABLE_NAME = :p_ci_runner_machine_builds
  BATCH_COLUMN = :build_id
  DELAY_INTERVAL = 2.minutes
  MAX_BATCH_SIZE = 150_000
  GITLAB_OPTIMIZED_BATCH_SIZE = 50_000
  GITLAB_OPTIMIZED_SUB_BATCH_SIZE = 250
  JOB_ARGS = %i[project_id p_ci_builds project_id build_id partition_id]

  def up
    return unless Gitlab.com_except_jh?

    # Clear previous background migration execution from QueueBackfillPCiRunnerMachineBuildsProjectId
    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)

    queue_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, *JOB_ARGS,
      job_interval: DELAY_INTERVAL,
      max_batch_size: MAX_BATCH_SIZE,
      batch_size: GITLAB_OPTIMIZED_BATCH_SIZE,
      sub_batch_size: GITLAB_OPTIMIZED_SUB_BATCH_SIZE)
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)
  end
end
# rubocop:enable BackgroundMigration/DictionaryFile
