# frozen_string_literal: true

class AddEndedAtToOnboardingProgresses < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :onboarding_progresses, :ended_at, :datetime_with_timezone
  end
end
