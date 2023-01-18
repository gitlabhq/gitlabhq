# frozen_string_literal: true

class AddUserDefaultsToPrivateProfileToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column(:application_settings, :user_defaults_to_private_profile, :boolean, default: false, null: false)
  end
end
