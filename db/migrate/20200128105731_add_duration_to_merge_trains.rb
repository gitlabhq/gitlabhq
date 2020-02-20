# frozen_string_literal: true

class AddDurationToMergeTrains < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :merge_trains, :merged_at, :datetime_with_timezone
    add_column :merge_trains, :duration, :integer
  end
end
