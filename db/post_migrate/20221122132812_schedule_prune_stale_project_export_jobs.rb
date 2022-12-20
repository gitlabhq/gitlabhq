# frozen_string_literal: true

class SchedulePruneStaleProjectExportJobs < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'PruneStaleProjectExportJobs'
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_export_jobs,
      :id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_export_jobs, :id, [])
  end
end
