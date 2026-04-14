# frozen_string_literal: true

class AddCiMaxArtifactSizeSarifToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :plan_limits, :ci_max_artifact_size_sarif, :integer, default: 10, null: false
  end
end
