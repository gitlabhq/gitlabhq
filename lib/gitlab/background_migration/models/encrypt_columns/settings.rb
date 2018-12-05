# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module Models
      module EncryptColumns
        # This model is shared between synchronous and background migrations to
        # encrypt the `runners_token` column in `application_settings` table.
        #
        class Settings < ActiveRecord::Base
          include ::EachBatch
          include ::CacheableAttributes

          self.table_name = 'application_settings'
          self.inheritance_column = :_type_disabled

          after_commit do
            ::ApplicationSetting.expire
          end

          def runners_registration_token=(value)
            self.runners_registration_token_encrypted =
              ::Gitlab::CryptoHelper.aes256_gcm_encrypt(value)
          end

          def self.encrypted_attributes
            {
              runners_registration_token: {
                attribute: :runners_registration_token_encrypted
              }
            }
          end
        end
      end
    end
  end
end
