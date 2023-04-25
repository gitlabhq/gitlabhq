# frozen_string_literal: true

class CleanupBackfillCiQueuingTables < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillCiQueuingTables'

  disable_ddl_transaction!

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
