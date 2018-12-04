# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module Models
      module EncryptColumns
        # This model is shared between synchronous and background migrations to
        # encrypt the `token` and `url` columns
        class WebHook < ActiveRecord::Base
          include ::EachBatch

          self.table_name = 'web_hooks'
          self.inheritance_column = :_type_disabled

          attr_encrypted :token,
                         mode:      :per_attribute_iv,
                         algorithm: 'aes-256-gcm',
                         key:       Settings.attr_encrypted_db_key_base_truncated

          attr_encrypted :url,
                         mode:      :per_attribute_iv,
                         algorithm: 'aes-256-gcm',
                         key:       Settings.attr_encrypted_db_key_base_truncated
        end
      end
    end
  end
end
