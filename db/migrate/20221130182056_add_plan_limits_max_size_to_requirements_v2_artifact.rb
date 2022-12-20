# frozen_string_literal: true

class AddPlanLimitsMaxSizeToRequirementsV2Artifact < Gitlab::Database::Migration[2.0]
  def change
    add_column :plan_limits, :ci_max_artifact_size_requirements_v2, :integer, null: false, default: 0
  end
end
