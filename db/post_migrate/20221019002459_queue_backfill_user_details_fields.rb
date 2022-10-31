# frozen_string_literal: true

class QueueBackfillUserDetailsFields < Gitlab::Database::Migration[2.0]
  MIGRATION = 'BackfillUserDetailsFields'
  INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(MIGRATION, :users, :id, job_interval: INTERVAL)
  end

  def down
    delete_batched_background_migration(MIGRATION, :users, :id, [])
  end
end
