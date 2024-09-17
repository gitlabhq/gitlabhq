# frozen_string_literal: true

class QueueBackfillCiJobVariablesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiJobVariablesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25000
  SUB_BATCH_SIZE = 150
  GITLAB_OPTIMIZED_BATCH_SIZE = 75_000
  GITLAB_OPTIMIZED_SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_job_variables,
      :id,
      :project_id,
      :p_ci_builds,
      :project_id,
      :job_id,
      job_interval: DELAY_INTERVAL,
      **batch_sizes
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_job_variables,
      :id,
      [
        :project_id,
        :p_ci_builds,
        :project_id,
        :job_id
      ]
    )
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
