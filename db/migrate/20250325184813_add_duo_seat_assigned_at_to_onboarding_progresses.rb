# frozen_string_literal: true

class AddDuoSeatAssignedAtToOnboardingProgresses < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :onboarding_progresses, :duo_seat_assigned_at, :datetime_with_timezone
  end
end
