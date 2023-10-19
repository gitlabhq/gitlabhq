# frozen_string_literal: true

class AddMaxLoginAttemptsToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :max_login_attempts, :integer, null: true
  end
end
