# frozen_string_literal: true

class AddEndsAtToOncallRotations < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :incident_management_oncall_rotations, :ends_at, :datetime_with_timezone
  end
end
