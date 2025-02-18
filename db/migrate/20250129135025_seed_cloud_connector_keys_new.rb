# frozen_string_literal: true

class SeedCloudConnectorKeysNew < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class CloudConnectorKeys < MigrationRecord
    self.table_name = 'cloud_connector_keys'
    encrypts :secret_key, key_provider: ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
  end

  def up
    old_key = Rails.application.credentials.openid_connect_signing_key
    new_key = OpenSSL::PKey::RSA.new(2048).to_pem

    CloudConnectorKeys.create!(secret_key: old_key)
    CloudConnectorKeys.create!(secret_key: new_key)
  end

  def down
    CloudConnectorKeys.delete_all
  end
end
