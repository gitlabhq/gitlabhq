# frozen_string_literal: true

class AddCiMaxArtifactSizeEnvironmentKeyToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :plan_limits, :ci_max_artifact_size_environment_key, :integer, default: 1, null: false
  end
end
