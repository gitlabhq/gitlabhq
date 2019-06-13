# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ResetEventsPrimaryKeySequence < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  class Event < ActiveRecord::Base
    self.table_name = 'events'
  end

  def up
    reset_pk_sequence!(Event.table_name)
  end

  def down
    # No-op
  end
end
