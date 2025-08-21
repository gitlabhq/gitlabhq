# frozen_string_literal: true

class QueueBackfillProjectRelationExportUploadsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillProjectRelationExportUploadsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_relation_export_uploads,
      :id,
      :project_id,
      :project_relation_exports,
      :project_id,
      :project_relation_export_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :project_relation_export_uploads,
      :id,
      [
        :project_id,
        :project_relation_exports,
        :project_id,
        :project_relation_export_id
      ]
    )
  end
end
