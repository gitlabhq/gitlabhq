# frozen_string_literal: true

class CleanupPopulateTopicsNonPrivateProjectsCount < Gitlab::Database::Migration[1.0]
  MIGRATION = 'PopulateTopicsNonPrivateProjectsCount'

  disable_ddl_transaction!

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
