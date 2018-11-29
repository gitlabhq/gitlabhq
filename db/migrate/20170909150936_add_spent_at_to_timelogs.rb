class AddSpentAtToTimelogs < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    add_column :timelogs, :spent_at, :datetime_with_timezone
  end

  def down
    remove_column :timelogs, :spent_at
  end
end
