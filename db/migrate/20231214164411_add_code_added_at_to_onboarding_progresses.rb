# frozen_string_literal: true

class AddCodeAddedAtToOnboardingProgresses < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  enable_lock_retries!

  def change
    add_column :onboarding_progresses, :code_added_at, :datetime_with_timezone
  end
end
