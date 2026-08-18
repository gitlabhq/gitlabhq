# frozen_string_literal: true

class RemoveCiMaxArtifactSizeScipFromPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    remove_column :plan_limits, :ci_max_artifact_size_scip, if_exists: true
  end

  def down
    add_column :plan_limits, :ci_max_artifact_size_scip, :integer,
      default: 200, null: false, if_not_exists: true
  end
end
