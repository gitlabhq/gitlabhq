# frozen_string_literal: true
class AddClosedColumnsToEpic < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_reference :epics, :closed_by, index: true
    add_column :epics, :closed_at, :datetime_with_timezone
  end

  def down
    remove_reference :epics, :closed_by, index: true
    remove_column :epics, :closed_at
  end
end
