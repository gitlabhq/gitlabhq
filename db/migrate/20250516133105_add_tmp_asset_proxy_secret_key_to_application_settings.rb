# frozen_string_literal: true

class AddTmpAssetProxySecretKeyToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :application_settings, :tmp_asset_proxy_secret_key, :jsonb
  end
end
