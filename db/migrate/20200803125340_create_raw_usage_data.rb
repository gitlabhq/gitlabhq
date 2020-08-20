# frozen_string_literal: true

class CreateRawUsageData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless table_exists?(:raw_usage_data)
      create_table :raw_usage_data do |t|
        t.timestamps_with_timezone
        t.datetime_with_timezone :recorded_at, null: false
        t.datetime_with_timezone :sent_at
        t.jsonb :payload, null: false

        t.index [:recorded_at], unique: true
      end
    end
  end

  def down
    drop_table :raw_usage_data
  end
end
