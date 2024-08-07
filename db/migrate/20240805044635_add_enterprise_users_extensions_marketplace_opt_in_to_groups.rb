# frozen_string_literal: true

class AddEnterpriseUsersExtensionsMarketplaceOptInToGroups < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :namespace_settings, :enterprise_users_extensions_marketplace_opt_in_status, :smallint, default: 0,
      null: false
  end
end
