# frozen_string_literal: true

class CreateGeoEvents < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :geo_events do |t|
      t.string :replicable_name, limit: 255, null: false
      t.string :event_name, limit: 255, null: false
      t.jsonb :payload, default: {}, null: false
      t.datetime_with_timezone :created_at, null: false
    end
  end
  # rubocop:enable Migration/PreventStrings
end
