# frozen_string_literal: true

class AddProjectCiSecureFilesToPlanLimits < Gitlab::Database::Migration[1.0]
  def change
    add_column(:plan_limits, :project_ci_secure_files, :integer, default: 100, null: false)
  end
end
