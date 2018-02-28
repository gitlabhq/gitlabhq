# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddBroadcastMessagesIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  COLUMNS = %i[starts_at ends_at id].freeze

  def up
    add_concurrent_index :broadcast_messages, COLUMNS
  end

  def down
    remove_concurrent_index :broadcast_messages, COLUMNS
  end
end
