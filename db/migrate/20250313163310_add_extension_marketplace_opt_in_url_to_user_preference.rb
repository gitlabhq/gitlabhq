# frozen_string_literal: true

class AddExtensionMarketplaceOptInUrlToUserPreference < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :user_preferences, :extensions_marketplace_opt_in_url, :text, null: true, if_not_exists: true
    end

    # This is well above the 253 full domain name limit. We go ahead and overshoot because
    # we may need to store paths in here in the future.
    # https://webmasters.stackexchange.com/a/16997
    add_text_limit :user_preferences, :extensions_marketplace_opt_in_url, 512
  end

  def down
    with_lock_retries do
      remove_column :user_preferences, :extensions_marketplace_opt_in_url, if_exists: true
    end
  end
end
