# frozen_string_literal: true

class UpdatePlanLimitsDefaults < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column_default :plan_limits, :project_hooks, 100
    change_column_default :plan_limits, :group_hooks, 50
    change_column_default :plan_limits, :ci_project_subscriptions, 2
    change_column_default :plan_limits, :ci_pipeline_schedules, 10
  end

  def down
    change_column_default :plan_limits, :project_hooks, 0
    change_column_default :plan_limits, :group_hooks, 0
    change_column_default :plan_limits, :ci_project_subscriptions, 0
    change_column_default :plan_limits, :ci_pipeline_schedules, 0
  end
end
