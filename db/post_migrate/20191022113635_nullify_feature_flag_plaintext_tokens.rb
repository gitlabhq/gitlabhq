# frozen_string_literal: true

class NullifyFeatureFlagPlaintextTokens < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  class FeatureFlagsClient < ActiveRecord::Base
    include EachBatch

    self.table_name = 'operations_feature_flags_clients'

    scope :with_encrypted_token, -> { where.not(token_encrypted: nil) }
    scope :with_plaintext_token, -> { where.not(token: nil) }
    scope :without_plaintext_token, -> { where(token: nil) }
  end

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee?

    # 7357 records to be updated on GitLab.com
    FeatureFlagsClient.with_encrypted_token.with_plaintext_token.each_batch do |relation|
      relation.update_all(token: nil)
    end
  end

  def down
    return unless Gitlab.ee?

    # There is no way to restore only the tokens that were NULLifyed in the `up`
    # but we can do is to restore _all_ of them in case it is needed.
    say_with_time('Decrypting tokens from operations_feature_flags_clients') do
      FeatureFlagsClient.with_encrypted_token.without_plaintext_token.find_each do |feature_flags_client|
        token = Gitlab::CryptoHelper.aes256_gcm_decrypt(feature_flags_client.token_encrypted)
        feature_flags_client.update_column(:token, token)
      end
    end
  end
end
