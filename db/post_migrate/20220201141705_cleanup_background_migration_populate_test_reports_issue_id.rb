# frozen_string_literal: true

class CleanupBackgroundMigrationPopulateTestReportsIssueId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'PopulateTestReportsIssueId'

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
