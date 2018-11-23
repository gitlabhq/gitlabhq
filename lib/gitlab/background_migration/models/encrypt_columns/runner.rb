# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module Models
      module EncryptColumns
        # This model is shared between synchronous and background migrations to
        # encrypt the `token` column in `ci_runners` table.
        #
        class Runner < ActiveRecord::Base
          include ::EachBatch

          self.table_name = 'ci_runners'
          self.inheritance_column = :_type_disabled

          def token=(value)
            self.token_encrypted =
              ::Gitlab::CryptoHelper.aes256_gcm_encrypt(value)
          end

          def self.encrypted_attributes
            { token: { attribute: :token_encrypted } }
          end
        end
      end
    end
  end
end
