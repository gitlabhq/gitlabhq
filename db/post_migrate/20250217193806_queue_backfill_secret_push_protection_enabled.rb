# frozen_string_literal: true

class QueueBackfillSecretPushProtectionEnabled < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  MIGRATION = 'BackfillSecretPushProtectionEnabled'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 100
  MAX_BATCH_SIZE = 10_000

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_security_settings,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION,
      :project_security_settings,
      :project_id,
      []
    )
  end
end
