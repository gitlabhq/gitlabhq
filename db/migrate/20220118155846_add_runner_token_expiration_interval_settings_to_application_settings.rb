# frozen_string_literal: true

class AddRunnerTokenExpirationIntervalSettingsToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    [:runner_token_expiration_interval, :group_runner_token_expiration_interval, :project_runner_token_expiration_interval].each do |field|
      add_column :application_settings, field, :integer
    end
  end
end
