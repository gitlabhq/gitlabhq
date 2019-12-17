# frozen_string_literal: true

class AddIdToPlanLimits < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column(:plan_limits, :id, :primary_key) unless column_exists?(:plan_limits, :id)
  end

  def down
    remove_column(:plan_limits, :id)
  end
end
