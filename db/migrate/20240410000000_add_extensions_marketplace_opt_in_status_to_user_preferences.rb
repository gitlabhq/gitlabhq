# frozen_string_literal: true

class AddExtensionsMarketplaceOptInStatusToUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :user_preferences, :extensions_marketplace_opt_in_status, :smallint, default: 0, null: false
  end
end
