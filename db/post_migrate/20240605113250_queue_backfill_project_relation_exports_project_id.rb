# frozen_string_literal: true

class QueueBackfillProjectRelationExportsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillProjectRelationExportsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_relation_exports,
      :id,
      :project_id,
      :project_export_jobs,
      :project_id,
      :project_export_job_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :project_relation_exports,
      :id,
      [
        :project_id,
        :project_export_jobs,
        :project_id,
        :project_export_job_id
      ]
    )
  end
end
