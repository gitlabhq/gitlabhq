# frozen_string_literal: true

class AddGeoEventIdToGeoEventLog < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :geo_event_log, :geo_event_id, :integer
  end
end
