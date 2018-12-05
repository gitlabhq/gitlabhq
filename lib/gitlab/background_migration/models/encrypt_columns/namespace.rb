# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module Models
      module EncryptColumns
        # This model is shared between synchronous and background migrations to
        # encrypt the `runners_token` column in `namespaces` table.
        #
        class Namespace < ActiveRecord::Base
          include ::EachBatch

          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled

          def runners_token=(value)
            self.runners_token_encrypted =
              ::Gitlab::CryptoHelper.aes256_gcm_encrypt(value)
          end

          def self.encrypted_attributes
            { runners_token: { attribute: :runners_token_encrypted } }
          end
        end
      end
    end
  end
end
