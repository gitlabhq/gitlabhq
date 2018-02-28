# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SwapEventMigrationTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    rename_tables
  end

  def down
    rename_tables
  end

  def rename_tables
    rename_table :events, :events_old
    rename_table :events_for_migration, :events
    rename_table :events_old, :events_for_migration
  end
end
