# frozen_string_literal: true

class AddProjectHooksToPlanLimits < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :project_hooks, :integer, default: 0, null: false)
  end
end
