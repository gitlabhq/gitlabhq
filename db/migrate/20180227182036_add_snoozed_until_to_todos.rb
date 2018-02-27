class AddSnoozedUntilToTodos < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :todos, :snoozed_until, :datetime_with_timezone
  end
end
