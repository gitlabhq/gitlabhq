# frozen_string_literal: true

class QueueFixIncoherentPackagesSizeOnProjectStatistics < Gitlab::Database::Migration[2.1]
  MIGRATION = 'FixIncoherentPackagesSizeOnProjectStatistics'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 17000

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Package < MigrationRecord
    self.table_name = 'packages_packages'
  end

  def up
    return unless ::QueueFixIncoherentPackagesSizeOnProjectStatistics::Package.exists?

    queue_batched_background_migration(
      MIGRATION,
      :project_statistics,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_statistics, :id, [])
  end
end
