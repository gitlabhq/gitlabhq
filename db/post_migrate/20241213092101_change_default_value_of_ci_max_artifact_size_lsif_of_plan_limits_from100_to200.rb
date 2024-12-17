# frozen_string_literal: true

class ChangeDefaultValueOfCiMaxArtifactSizeLsifOfPlanLimitsFrom100To200 < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    change_column_default('plan_limits', 'ci_max_artifact_size_lsif', from: 100, to: 200)
  end
end
