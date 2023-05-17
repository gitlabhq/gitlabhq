# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migration to make sure that all the prevously saved tokens have their encrypted values in the db.
    class EncryptCiTriggerToken < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :continuous_integration
      scope_to ->(relation) { relation.where(encrypted_token: nil) }
      operation_name :update
      # Class that is imitating Ci::Trigger
      class CiTrigger < ::Ci::ApplicationRecord
        ALGORITHM = 'aes-256-gcm'

        self.table_name = 'ci_triggers'

        attr_encrypted :encrypted_token_tmp,
          attribute: :encrypted_token,
          mode: :per_attribute_iv,
          algorithm: 'aes-256-gcm',
          key: Settings.attr_encrypted_db_key_base_32,
          encode: false

        before_save :copy_token_to_encrypted_token

        def copy_token_to_encrypted_token
          self.encrypted_token_tmp = token
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |trigger|
            Gitlab::BackgroundMigration::EncryptCiTriggerToken::CiTrigger.find(trigger.id).save!
          end
        end
      end
    end
  end
end
