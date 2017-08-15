# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddBroadcastMessageNotNullConstraints < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  COLUMNS = %i[starts_at ends_at created_at updated_at message_html]

  class BroadcastMessage < ActiveRecord::Base
    self.table_name = 'broadcast_messages'
  end

  def up
    COLUMNS.each do |column|
      BroadcastMessage.where(column => nil).delete_all

      change_column_null :broadcast_messages, column, false
    end
  end

  def down
    COLUMNS.each do |column|
      change_column_null :broadcast_messages, column, true
    end
  end
end
