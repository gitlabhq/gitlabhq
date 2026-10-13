# frozen_string_literal: true

class UpdateAiFlowSchedulesPlanLimitDefault < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def up
    change_column_default :plan_limits, :ai_flow_schedules, from: 10, to: 100
  end

  def down
    change_column_default :plan_limits, :ai_flow_schedules, from: 100, to: 10
  end
end
