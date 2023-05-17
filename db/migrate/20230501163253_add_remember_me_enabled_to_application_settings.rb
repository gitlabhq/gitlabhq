# frozen_string_literal: true

class AddRememberMeEnabledToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :remember_me_enabled, :boolean, default: true, null: false
  end
end
