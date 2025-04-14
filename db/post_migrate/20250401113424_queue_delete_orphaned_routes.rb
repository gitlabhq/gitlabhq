# frozen_string_literal: true

class QueueDeleteOrphanedRoutes < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "DeleteOrphanedRoutes"
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :routes,
      :id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :routes, :id, [])
  end
end
