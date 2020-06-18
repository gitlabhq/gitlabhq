# frozen_string_literal: true

class AddInstanceLevelVariablesColumnToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :ci_instance_level_variables, :integer, default: 25, null: false
  end
end
