# frozen_string_literal: true

class UpdateTrialPlansCiDailyPipelineScheduleTriggers < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  PREMIUM_TRIAL = 'premium_trial'
  ULTIMATE_TRIAL = 'ultimate_trial'
  EVERY_5_MINUTES = (1.day.in_minutes / 5).to_i

  class Plan < ActiveRecord::Base
    self.table_name = 'plans'
    self.inheritance_column = :_type_disabled

    has_one :limits, class_name: 'PlanLimits'
  end

  class PlanLimits < ActiveRecord::Base
    self.table_name = 'plan_limits'
    self.inheritance_column = :_type_disabled

    belongs_to :plan
  end

  def plan_limits_present?
    premium_trial_plan = Plan.find_by(name: PREMIUM_TRIAL)
    ultimate_trial_plan = Plan.find_by(name: ULTIMATE_TRIAL)

    premium_trial_plan && premium_trial_plan.limits && ultimate_trial_plan && ultimate_trial_plan.limits
  end

  def up
    return unless Gitlab.dev_env_or_com?

    if plan_limits_present?
      create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', PREMIUM_TRIAL, EVERY_5_MINUTES)
      create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', ULTIMATE_TRIAL, EVERY_5_MINUTES)
    end
  end

  def down
    return unless Gitlab.dev_env_or_com?

    if plan_limits_present?
      create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', PREMIUM_TRIAL, 0)
      create_or_update_plan_limit('ci_daily_pipeline_schedule_triggers', ULTIMATE_TRIAL, 0)
    end
  end
end
