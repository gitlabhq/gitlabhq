# frozen_string_literal: true

class EncryptDeployTokensTokens < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  class DeploymentTokens < ActiveRecord::Base
    self.table_name = 'deploy_tokens'
  end

  def up
    say_with_time("Encrypting tokens from deploy_tokens") do
      DeploymentTokens.where('token_encrypted is NULL AND token IS NOT NULL').find_each(batch_size: 10000) do |deploy_token|
        token_encrypted = Gitlab::CryptoHelper.aes256_gcm_encrypt(deploy_token.token)
        deploy_token.update!(token_encrypted: token_encrypted)
      end
    end
  end

  def down
    say_with_time("Decrypting tokens from deploy_tokens") do
      DeploymentTokens.where('token_encrypted IS NOT NULL AND token IS NULL').find_each(batch_size: 10000) do |deploy_token|
        token = Gitlab::CryptoHelper.aes256_gcm_decrypt(deploy_token.token_encrypted)
        deploy_token.update!(token: token)
      end
    end
  end
end
