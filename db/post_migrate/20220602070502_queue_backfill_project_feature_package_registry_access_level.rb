# frozen_string_literal: true

class QueueBackfillProjectFeaturePackageRegistryAccessLevel < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  MIGRATION = 'BackfillProjectFeaturePackageRegistryAccessLevel'
  DELAY_INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end
end
