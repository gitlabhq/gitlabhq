# frozen_string_literal: true

class MoveLimitsFromPlans < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    execute <<~SQL
      INSERT INTO plan_limits (plan_id, ci_active_pipelines, ci_pipeline_size, ci_active_jobs)
      SELECT id, COALESCE(active_pipelines_limit, 0), COALESCE(pipeline_size_limit, 0), COALESCE(active_jobs_limit, 0)
      FROM plans
    SQL
  end

  def down
    execute 'DELETE FROM plan_limits'
  end
end
