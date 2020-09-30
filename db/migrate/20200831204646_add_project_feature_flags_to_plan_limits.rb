# frozen_string_literal: true

class AddProjectFeatureFlagsToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :project_feature_flags, :integer, default: 200, null: false)
  end
end
