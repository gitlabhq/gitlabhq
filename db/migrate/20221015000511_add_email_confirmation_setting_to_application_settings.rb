# frozen_string_literal: true

class AddEmailConfirmationSettingToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :email_confirmation_setting, :integer, limit: 2, default: 2
  end
end
