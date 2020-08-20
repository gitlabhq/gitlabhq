# frozen_string_literal: true

class ChangeDefaultValueOfCiMaxArtifactSizeTerraformOfPlanLimitsFrom0To5 < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :plan_limits, :ci_max_artifact_size_terraform, 5
      execute('UPDATE plan_limits SET ci_max_artifact_size_terraform = 5 WHERE ci_max_artifact_size_terraform = 0')
    end
  end

  def down
    with_lock_retries do
      change_column_default :plan_limits, :ci_max_artifact_size_terraform, 0
      execute('UPDATE plan_limits SET ci_max_artifact_size_terraform = 0 WHERE ci_max_artifact_size_terraform = 5')
    end
  end
end
