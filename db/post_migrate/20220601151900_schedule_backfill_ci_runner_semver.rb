# frozen_string_literal: true

class ScheduleBackfillCiRunnerSemver < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillCiRunnerSemver'
  INTERVAL = 2.minutes.freeze
  BATCH_SIZE = 500
  MAX_BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!

  def up
    # Disabled background migration introduced in same milestone as it was decided to change approach
    # and the semver column will no longer be needed
    # queue_batched_background_migration(
    #   MIGRATION,
    #   :ci_runners,
    #   :id,
    #   job_interval: INTERVAL,
    #   batch_size: BATCH_SIZE,
    #   max_batch_size: MAX_BATCH_SIZE,
    #   sub_batch_size: SUB_BATCH_SIZE
    # )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runners, :id, [])
  end
end
