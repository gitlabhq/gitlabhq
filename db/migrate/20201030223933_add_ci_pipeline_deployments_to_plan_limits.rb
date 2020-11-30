# frozen_string_literal: true

class AddCiPipelineDeploymentsToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :ci_pipeline_deployments, :integer, default: 500, null: false
  end
end
