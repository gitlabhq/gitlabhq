# frozen_string_literal: true

class AddRunnerRegistrationEnabledToNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :runner_registration_enabled, :boolean, default: true
  end
end
