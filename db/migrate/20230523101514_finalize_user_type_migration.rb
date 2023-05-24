# frozen_string_literal: true

class FinalizeUserTypeMigration < Gitlab::Database::Migration[2.1]
  MIGRATION = 'MigrateHumanUserType'

  disable_ddl_transaction!

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
