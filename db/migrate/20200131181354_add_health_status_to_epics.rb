# frozen_string_literal: true

class AddHealthStatusToEpics < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :epics, :health_status, :integer, limit: 2
  end
end
