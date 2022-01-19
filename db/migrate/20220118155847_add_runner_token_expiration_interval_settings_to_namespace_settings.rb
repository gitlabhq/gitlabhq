# frozen_string_literal: true

class AddRunnerTokenExpirationIntervalSettingsToNamespaceSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    [:runner_token_expiration_interval, :subgroup_runner_token_expiration_interval, :project_runner_token_expiration_interval].each do |field|
      add_column :namespace_settings, field, :integer
    end
  end
end
