# frozen_string_literal: true

class ScheduleMigrationToHashedStorage < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  MIGRATION = 'MigrateToHashedStorage'

  disable_ddl_transaction!

  def up
    migrate_async(MIGRATION)
  end

  def down
    # NO-OP
  end
end
