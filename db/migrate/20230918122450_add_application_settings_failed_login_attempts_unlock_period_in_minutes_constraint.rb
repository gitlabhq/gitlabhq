# frozen_string_literal: true

class AddApplicationSettingsFailedLoginAttemptsUnlockPeriodInMinutesConstraint < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'app_settings_failed_login_attempts_unlock_period_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'failed_login_attempts_unlock_period_in_minutes > 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
