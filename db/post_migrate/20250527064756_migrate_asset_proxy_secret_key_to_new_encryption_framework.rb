# frozen_string_literal: true

class MigrateAssetProxySecretKeyToNewEncryptionFramework < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class MigrationApplicationSettings < MigrationRecord
    include Gitlab::EncryptedAttribute

    self.table_name = 'application_settings'

    migrate_to_encrypts :asset_proxy_secret_key,
      mode: :per_attribute_iv,
      key: :db_key_base_truncated,
      algorithm: 'aes-256-cbc',
      insecure_mode: true
  end

  def up
    count = MigrationApplicationSettings.count

    if count != 1
      ::Gitlab::BackgroundMigration::Logger.error(
        message: "There is more or less than 1 application_settings table (#{count} tables)."
      )
      return
    end

    setting = MigrationApplicationSettings.last

    setting.asset_proxy_secret_key = setting.attr_encrypted_asset_proxy_secret_key
    setting.save!

    setting = MigrationApplicationSettings.last

    return if setting.asset_proxy_secret_key == setting.attr_encrypted_asset_proxy_secret_key

    raise StandardError, "asset_proxy_secret_key migration check failed."
  end

  def down
    execute "UPDATE application_settings SET tmp_asset_proxy_secret_key = NULL"
  end
end
