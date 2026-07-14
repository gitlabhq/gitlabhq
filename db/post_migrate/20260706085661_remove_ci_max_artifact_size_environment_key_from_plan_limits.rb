# frozen_string_literal: true

class RemoveCiMaxArtifactSizeEnvironmentKeyFromPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    remove_column :plan_limits, :ci_max_artifact_size_environment_key, if_exists: true
  end

  def down
    add_column :plan_limits, :ci_max_artifact_size_environment_key, :integer,
      default: 1, null: false, if_not_exists: true
  end
end
