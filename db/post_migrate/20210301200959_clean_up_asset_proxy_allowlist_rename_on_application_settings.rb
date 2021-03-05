# frozen_string_literal: true

class CleanUpAssetProxyAllowlistRenameOnApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers::V2

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings,
      :asset_proxy_allowlist,
      :asset_proxy_whitelist
  end

  def down
    undo_cleanup_concurrent_column_rename :application_settings,
      :asset_proxy_allowlist,
      :asset_proxy_whitelist
  end
end
