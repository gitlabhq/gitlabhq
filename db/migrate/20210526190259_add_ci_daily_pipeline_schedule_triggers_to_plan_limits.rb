# frozen_string_literal: true

class AddCiDailyPipelineScheduleTriggersToPlanLimits < ActiveRecord::Migration[6.0]
  def change
    add_column(:plan_limits, :ci_daily_pipeline_schedule_triggers, :integer, default: 0, null: false)
  end
end
