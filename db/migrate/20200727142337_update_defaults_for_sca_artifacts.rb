# frozen_string_literal: true

class UpdateDefaultsForScaArtifacts < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  DEPENDENCY_SCANNING_LIMIT_MB = 350
  CONTAINER_SCANNING_LIMIT_MB = 150
  LICENSE_SCANNING_LIMIT_MB = 100

  def up
    change_column_default :plan_limits, :ci_max_artifact_size_dependency_scanning, DEPENDENCY_SCANNING_LIMIT_MB
    change_column_default :plan_limits, :ci_max_artifact_size_container_scanning, CONTAINER_SCANNING_LIMIT_MB
    change_column_default :plan_limits, :ci_max_artifact_size_license_scanning, LICENSE_SCANNING_LIMIT_MB
  end

  def down
    change_column_default :plan_limits, :ci_max_artifact_size_dependency_scanning, 0
    change_column_default :plan_limits, :ci_max_artifact_size_container_scanning, 0
    change_column_default :plan_limits, :ci_max_artifact_size_license_scanning, 0
  end
end
