# frozen_string_literal: true

class QueueBackfillPackagesPackageFilesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillPackagesPackageFilesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_package_files,
      :id,
      :project_id,
      :packages_packages,
      :project_id,
      :package_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :packages_package_files,
      :id,
      [
        :project_id,
        :packages_packages,
        :project_id,
        :package_id
      ]
    )
  end
end
