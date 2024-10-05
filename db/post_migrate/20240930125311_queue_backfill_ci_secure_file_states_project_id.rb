# frozen_string_literal: true

class QueueBackfillCiSecureFileStatesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiSecureFileStatesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_secure_file_states,
      :ci_secure_file_id,
      :project_id,
      :ci_secure_files,
      :project_id,
      :ci_secure_file_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_secure_file_states,
      :ci_secure_file_id,
      [
        :project_id,
        :ci_secure_files,
        :project_id,
        :ci_secure_file_id
      ]
    )
  end
end
