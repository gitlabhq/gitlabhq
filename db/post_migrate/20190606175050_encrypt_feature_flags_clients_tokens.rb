# frozen_string_literal: true

class EncryptFeatureFlagsClientsTokens < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  class FeatureFlagsClient < ActiveRecord::Base
    self.table_name = 'operations_feature_flags_clients'
  end

  def up
    say_with_time("Encrypting tokens from operations_feature_flags_clients") do
      FeatureFlagsClient.where('token_encrypted is NULL AND token IS NOT NULL').find_each do |feature_flags_client|
        token_encrypted = Gitlab::CryptoHelper.aes256_gcm_encrypt(feature_flags_client.token)
        feature_flags_client.update!(token_encrypted: token_encrypted)
      end
    end
  end

  def down
    say_with_time("Decrypting tokens from operations_feature_flags_clients") do
      FeatureFlagsClient.where('token_encrypted IS NOT NULL AND token IS NULL').find_each do |feature_flags_client|
        token = Gitlab::CryptoHelper.aes256_gcm_decrypt(feature_flags_client.token_encrypted)
        feature_flags_client.update!(token: token)
      end
    end
  end
end
