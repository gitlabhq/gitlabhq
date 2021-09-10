# frozen_string_literal: true

class AddDastSchedulesToPlanLimits < Gitlab::Database::Migration[1.0]
  def change
    add_column(:plan_limits, :dast_profile_schedules, :integer, default: 1, null: false)
  end
end
