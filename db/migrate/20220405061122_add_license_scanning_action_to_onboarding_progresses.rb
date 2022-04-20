# frozen_string_literal: true

class AddLicenseScanningActionToOnboardingProgresses < Gitlab::Database::Migration[1.0]
  def change
    add_column :onboarding_progresses, :license_scanning_run_at, :datetime_with_timezone
  end
end
