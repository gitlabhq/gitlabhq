# frozen_string_literal: true

class InsertCiPipelineSchedulesPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('ci_pipeline_schedules', 'free', 10)
    create_or_update_plan_limit('ci_pipeline_schedules', 'bronze', 50)
    create_or_update_plan_limit('ci_pipeline_schedules', 'silver', 50)
    create_or_update_plan_limit('ci_pipeline_schedules', 'gold', 50)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('ci_pipeline_schedules', 'free', 0)
    create_or_update_plan_limit('ci_pipeline_schedules', 'bronze', 0)
    create_or_update_plan_limit('ci_pipeline_schedules', 'silver', 0)
    create_or_update_plan_limit('ci_pipeline_schedules', 'gold', 0)
  end
end
