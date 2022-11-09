# frozen_string_literal: true

class QueuePopulateProjectsStarCount < Gitlab::Database::Migration[2.0]
  MIGRATION = 'PopulateProjectsStarCount'
  DELAY_INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      job_interval: DELAY_INTERVAL,
      sub_batch_size: 50
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end
end
