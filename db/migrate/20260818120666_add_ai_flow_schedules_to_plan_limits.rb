# frozen_string_literal: true

class AddAiFlowSchedulesToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :plan_limits, :ai_flow_schedules, :integer, default: 10, null: false
  end
end
