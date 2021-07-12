# frozen_string_literal: true

class AddErrorTrackingCounterCache < ActiveRecord::Migration[6.1]
  def up
    add_column :error_tracking_errors, :events_count, :bigint, null: false, default: 0
  end

  def down
    remove_column :error_tracking_errors, :events_count
  end
end
