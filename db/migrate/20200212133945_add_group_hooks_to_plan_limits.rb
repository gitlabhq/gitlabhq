# frozen_string_literal: true

class AddGroupHooksToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :group_hooks, :integer, default: 0, null: false)
  end
end
