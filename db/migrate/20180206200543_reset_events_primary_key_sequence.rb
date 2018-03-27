# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ResetEventsPrimaryKeySequence < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  class Event < ActiveRecord::Base
    self.table_name = 'events'
  end

  def up
    if Gitlab::Database.postgresql?
      reset_primary_key_for_postgresql
    else
      reset_primary_key_for_mysql
    end
  end

  def down
    # No-op
  end

  def reset_primary_key_for_postgresql
    reset_pk_sequence!(Event.table_name)
  end

  def reset_primary_key_for_mysql
    amount = Event.pluck('COALESCE(MAX(id), 1)').first

    execute "ALTER TABLE #{Event.table_name} AUTO_INCREMENT = #{amount}"
  end
end
