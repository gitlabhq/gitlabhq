# frozen_string_literal: true

class AddFailedLoginAttemptsUnlockPeriodInMinutesToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :failed_login_attempts_unlock_period_in_minutes, :integer, null: true
  end
end
