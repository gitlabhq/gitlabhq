# frozen_string_literal: true

class QueueBackfillSecurityScanProfilesNameAndDesc < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillSecurityScanProfilesNameAndDesc"
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :security_scan_profiles,
      :id,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :security_scan_profiles, :id, [])
  end
end
