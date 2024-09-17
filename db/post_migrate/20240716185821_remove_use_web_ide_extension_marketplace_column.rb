# frozen_string_literal: true

class RemoveUseWebIdeExtensionMarketplaceColumn < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    remove_column :user_preferences, :use_web_ide_extension_marketplace
  end

  def down
    add_column :user_preferences, :use_web_ide_extension_marketplace, :boolean, default: false, null: false
  end
end
