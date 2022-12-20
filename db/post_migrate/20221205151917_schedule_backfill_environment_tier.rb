# frozen_string_literal: true

class ScheduleBackfillEnvironmentTier < Gitlab::Database::Migration[2.0]
  MIGRATION = 'BackfillEnvironmentTiers'
  DELAY_INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :environments,
      :id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :environments, :id, [])
  end
end
