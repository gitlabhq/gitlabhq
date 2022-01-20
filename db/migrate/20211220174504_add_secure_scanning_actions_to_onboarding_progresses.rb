# frozen_string_literal: true

class AddSecureScanningActionsToOnboardingProgresses < Gitlab::Database::Migration[1.0]
  def change
    change_table(:onboarding_progresses, bulk: true) do |t|
      t.column :secure_dependency_scanning_run_at, :datetime_with_timezone
      t.column :secure_container_scanning_run_at, :datetime_with_timezone
      t.column :secure_dast_run_at, :datetime_with_timezone
      t.column :secure_secret_detection_run_at, :datetime_with_timezone
      t.column :secure_coverage_fuzzing_run_at, :datetime_with_timezone
      t.column :secure_cluster_image_scanning_run_at, :datetime_with_timezone
      t.column :secure_api_fuzzing_run_at, :datetime_with_timezone
    end
  end
end
