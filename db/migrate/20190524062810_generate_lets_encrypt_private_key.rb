# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class GenerateLetsEncryptPrivateKey < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'

    attr_encrypted :lets_encrypt_private_key,
                   mode: :per_attribute_iv,
                   key: Settings.attr_encrypted_db_key_base_truncated,
                   algorithm: 'aes-256-gcm',
                   encode: true
  end

  def up
    ApplicationSetting.reset_column_information

    private_key = OpenSSL::PKey::RSA.new(4096).to_pem
    ApplicationSetting.find_each do |setting|
      setting.update!(lets_encrypt_private_key: private_key)
    end
  end

  def down
  end
end
