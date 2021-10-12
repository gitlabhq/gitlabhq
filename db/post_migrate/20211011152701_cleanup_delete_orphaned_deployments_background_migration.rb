# frozen_string_literal: true

class CleanupDeleteOrphanedDeploymentsBackgroundMigration < Gitlab::Database::Migration[1.0]
  MIGRATION = 'DeleteOrphanedDeployments'

  disable_ddl_transaction!

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
