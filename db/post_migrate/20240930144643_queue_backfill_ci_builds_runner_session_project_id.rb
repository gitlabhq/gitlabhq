# frozen_string_literal: true

class QueueBackfillCiBuildsRunnerSessionProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiBuildsRunnerSessionProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_builds_runner_session,
      :id,
      :project_id,
      :p_ci_builds,
      :project_id,
      :build_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_builds_runner_session,
      :id,
      [
        :project_id,
        :p_ci_builds,
        :project_id,
        :build_id
      ]
    )
  end
end
