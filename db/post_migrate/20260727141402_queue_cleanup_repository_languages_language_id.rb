# frozen_string_literal: true

class QueueCleanupRepositoryLanguagesLanguageId < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'CleanupRepositoryLanguagesLanguageId'
  BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 1_000
  PAUSE_MS = 100
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :repository_languages,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      pause_ms: PAUSE_MS
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :repository_languages, :project_id, [])
  end
end
