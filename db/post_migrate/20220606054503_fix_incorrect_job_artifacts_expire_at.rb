# frozen_string_literal: true

class FixIncorrectJobArtifactsExpireAt < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'RemoveBackfilledJobArtifactsExpireAt'
  BATCH_CLASS = 'RemoveBackfilledJobArtifactsExpireAtBatchingStrategy'
  BATCH_SIZE = 500
  INTERVAL = 2.minutes.freeze

  def up
    return if Gitlab.com?

    queue_batched_background_migration(
      MIGRATION,
      :ci_job_artifacts,
      :id,
      job_interval: INTERVAL,
      batch_class_name: BATCH_CLASS,
      batch_size: BATCH_SIZE
    )
  end

  def down
    return if Gitlab.com?

    delete_batched_background_migration(MIGRATION, :ci_job_artifacts, :id, [])
  end
end
