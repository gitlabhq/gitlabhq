# frozen_string_literal: true

module Ai
  class ServiceAccessToken < ApplicationRecord
    self.table_name = 'service_access_tokens'

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false

    validates :token, presence: true

    enum category: {
      code_suggestions: 1
    }

    validates :category, presence: true
  end
end
