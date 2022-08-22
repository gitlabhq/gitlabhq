# frozen_string_literal: true

class AddAutoBanUserToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :auto_ban_user_on_excessive_projects_download, :boolean,
      default: false, null: false
  end
end
