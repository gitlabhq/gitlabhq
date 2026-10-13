# frozen_string_literal: true

class QueueBackfillArchivedInSecurityScanProfilesProjects < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = 'BackfillArchivedInSecurityScanProfilesProjects'
  BATCH_SIZE = 5_000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :security_scan_profiles_projects,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: 2.minutes
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :security_scan_profiles_projects, :id, [])
  end
end
