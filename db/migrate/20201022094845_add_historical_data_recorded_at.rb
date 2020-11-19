# frozen_string_literal: true

class AddHistoricalDataRecordedAt < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column(:historical_data, :recorded_at, :timestamptz)
  end

  def down
    remove_column(:historical_data, :recorded_at)
  end
end
