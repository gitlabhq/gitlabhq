# frozen_string_literal: true

class BackfillIntegrationsTypeNew < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

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
    delete_batched_background_migration(MIGRATION, :integrations, :id, [])
  end
end
