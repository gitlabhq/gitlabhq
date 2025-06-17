# frozen_string_literal: true

class QueueBackfillUpsertedCiBuildTraceMetadataProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillUpsertedCiBuildTraceMetadataProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25_000
  SUB_BATCH_SIZE = 150

  def up
    queue_batched_background_migration(
      MIGRATION,
      :p_ci_build_trace_metadata,
      :build_id,
      :project_id,
      :p_ci_builds,
      :project_id,
      :build_id,
      :partition_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :p_ci_build_trace_metadata,
      :build_id,
      [
        :project_id,
        :p_ci_builds,
        :project_id,
        :build_id,
        :partition_id
      ]
    )
  end
end
