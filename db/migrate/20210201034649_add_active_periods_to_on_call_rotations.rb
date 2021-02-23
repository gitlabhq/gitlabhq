# frozen_string_literal: true

class AddActivePeriodsToOnCallRotations < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :incident_management_oncall_rotations, :active_period_start, :time, null: true
    add_column :incident_management_oncall_rotations, :active_period_end, :time, null: true
  end
end
