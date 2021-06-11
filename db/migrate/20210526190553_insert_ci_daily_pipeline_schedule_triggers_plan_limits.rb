# frozen_string_literal: true

class InsertCiDailyPipelineScheduleTriggersPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  EVERY_5_MINUTES = (1.day.in_minutes / 5).to_i
  EVERY_HOUR = 1.day.in_hours.to_i

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'free', EVERY_HOUR)
    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'bronze', EVERY_5_MINUTES)
    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'silver', EVERY_5_MINUTES)
    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'gold', EVERY_5_MINUTES)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'free', 0)
    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'bronze', 0)
    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'silver', 0)
    create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', 'gold', 0)
  end
end
