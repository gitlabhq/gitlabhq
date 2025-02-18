# frozen_string_literal: true

class AddVSCodeExtensionMarketplaceToApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  enable_lock_retries!

  def change
    add_column :application_settings, :vscode_extension_marketplace, :jsonb, default: {}, null: false
  end
end
