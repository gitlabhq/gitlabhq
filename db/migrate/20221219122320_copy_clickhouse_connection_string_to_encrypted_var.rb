# frozen_string_literal: true
class CopyClickhouseConnectionStringToEncryptedVar < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'

    attr_encrypted :product_analytics_clickhouse_connection_string, {
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: true
    }.merge(encode: false, encode_iv: false)
  end

  def up
    setting = ApplicationSetting.first

    setting.update!(product_analytics_clickhouse_connection_string: setting.clickhouse_connection_string) if setting
  end

  def down
    # no-op
  end
end
