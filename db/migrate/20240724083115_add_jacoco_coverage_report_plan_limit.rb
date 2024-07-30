# frozen_string_literal: true

class AddJacocoCoverageReportPlanLimit < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :plan_limits, :ci_max_artifact_size_jacoco, :bigint, default: 0, null: false
  end
end
