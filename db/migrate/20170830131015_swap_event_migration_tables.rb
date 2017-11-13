# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SwapEventMigrationTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  class Event < ActiveRecord::Base
    self.table_name = 'events'
  end

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

    # Once swapped we need to reset the primary key of the new "events" table to
    # make sure that data created starts with the right value. This isn't
    # necessary for events_for_migration since we replicate existing primary key
    # values to it.
    if Gitlab::Database.postgresql?
      reset_primary_key_for_postgresql
    else
      reset_primary_key_for_mysql
    end
  end

  def reset_primary_key_for_postgresql
    reset_pk_sequence!(Event.table_name)
  end

  def reset_primary_key_for_mysql
    amount = Event.pluck('COALESCE(MAX(id), 1)').first

    execute "ALTER TABLE #{Event.table_name} AUTO_INCREMENT = #{amount}"
  end
end
