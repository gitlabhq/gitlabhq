# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddBroadcastMessageNotNullConstraints < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  COLUMNS = %i[starts_at ends_at created_at updated_at message_html]

  def change
    COLUMNS.each do |column|
      change_column_null :broadcast_messages, column, false
    end
  end
end
