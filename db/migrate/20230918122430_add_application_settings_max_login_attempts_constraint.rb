# frozen_string_literal: true

class AddApplicationSettingsMaxLoginAttemptsConstraint < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'app_settings_max_login_attempts_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'max_login_attempts > 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
