# frozen_string_literal: true

class AddAllowRegistrationTokenToNamespaceSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :allow_runner_registration_token, :boolean, default: true, null: false
  end
end
