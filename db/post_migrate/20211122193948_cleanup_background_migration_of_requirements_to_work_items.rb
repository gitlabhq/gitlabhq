# frozen_string_literal: true

class CleanupBackgroundMigrationOfRequirementsToWorkItems < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'MigrateRequirementsToWorkItems'

  disable_ddl_transaction!

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
