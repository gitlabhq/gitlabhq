# frozen_string_literal: true

class BackfillIntegrationsTypeNew < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'BackfillIntegrationsTypeNew'
  INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :integrations,
      :id,
      job_interval: INTERVAL
    )
  end

  def down
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(MIGRATION, :integrations, :id, [])
      .delete_all
  end
end
