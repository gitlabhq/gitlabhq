# frozen_string_literal: true

class RenameAssetProxyWhitelistOnApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers::V2

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :application_settings,
      :asset_proxy_whitelist,
      :asset_proxy_allowlist
  end

  def down
    undo_rename_column_concurrently :application_settings,
      :asset_proxy_whitelist,
      :asset_proxy_allowlist
  end
end
