# frozen_string_literal: true

class AddAllowRegistrationTokenToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :allow_runner_registration_token, :boolean, default: true, null: false
  end
end
