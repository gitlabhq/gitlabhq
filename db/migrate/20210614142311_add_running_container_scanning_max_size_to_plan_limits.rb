# frozen_string_literal: true

class AddRunningContainerScanningMaxSizeToPlanLimits < ActiveRecord::Migration[6.0]
  def change
    add_column :plan_limits, :ci_max_artifact_size_running_container_scanning, :integer, null: false, default: 0
  end
end
