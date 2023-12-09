# frozen_string_literal: true

class AddUseWebIdeExtensionMarketplaceToUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :user_preferences, :use_web_ide_extension_marketplace, :boolean, default: false, null: false
  end
end
