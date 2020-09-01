# frozen_string_literal: true

class CreateAnalyticsInstanceStatisticsMeasurements < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  UNIQUE_INDEX_NAME = 'index_on_instance_statistics_recorded_at_and_identifier'

  def change
    create_table :analytics_instance_statistics_measurements do |t|
      t.bigint :count, null: false
      t.datetime_with_timezone :recorded_at, null: false
      t.integer :identifier, limit: 2, null: false
    end

    add_index :analytics_instance_statistics_measurements, [:identifier, :recorded_at], unique: true, name: UNIQUE_INDEX_NAME
  end
end
