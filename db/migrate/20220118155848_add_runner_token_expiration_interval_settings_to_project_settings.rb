# frozen_string_literal: true

class AddRunnerTokenExpirationIntervalSettingsToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_ci_cd_settings, :runner_token_expiration_interval, :integer
  end
end
