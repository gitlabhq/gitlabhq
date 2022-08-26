# frozen_string_literal: true

class AddAutoBanUserToNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :auto_ban_user_on_excessive_projects_download, :boolean,
      default: false, null: false
  end
end
