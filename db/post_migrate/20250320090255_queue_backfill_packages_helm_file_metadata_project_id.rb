# frozen_string_literal: true

class QueueBackfillPackagesHelmFileMetadataProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillPackagesHelmFileMetadataProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_helm_file_metadata,
      :package_file_id,
      :project_id,
      :packages_package_files,
      :project_id,
      :package_file_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :packages_helm_file_metadata,
      :package_file_id,
      [
        :project_id,
        :packages_package_files,
        :project_id,
        :package_file_id
      ]
    )
  end
end
