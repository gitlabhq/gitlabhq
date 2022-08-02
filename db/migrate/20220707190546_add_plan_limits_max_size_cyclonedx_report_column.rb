# frozen_string_literal: true

class AddPlanLimitsMaxSizeCyclonedxReportColumn < Gitlab::Database::Migration[2.0]
  def change
    add_column :plan_limits, :ci_max_artifact_size_cyclonedx, :integer, null: false, default: 1
  end
end
