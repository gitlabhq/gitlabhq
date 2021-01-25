# frozen_string_literal: true

class CancelArtifactExpiryBackfill < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'BackfillArtifactExpiryDate'

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION) do |job|
      job.delete

      false
    end
  end

  def down
    # no-op
  end
end
