# frozen_string_literal: true

class AddRunnerRegistrationEnabledToProjectSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :project_settings, :runner_registration_enabled, :boolean, default: true
  end
end
