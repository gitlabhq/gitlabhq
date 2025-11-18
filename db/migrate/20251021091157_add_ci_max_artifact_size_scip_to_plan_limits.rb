# frozen_string_literal: true

class AddCiMaxArtifactSizeScipToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :plan_limits, :ci_max_artifact_size_scip, :integer, default: 200, null: false
  end
end
