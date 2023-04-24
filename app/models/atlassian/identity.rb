# frozen_string_literal: true

module Atlassian
  class Identity < ApplicationRecord
    self.table_name = 'atlassian_identities'

    belongs_to :user

    validates :extern_uid, presence: true, uniqueness: true
    validates :user, presence: true, uniqueness: true

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false

    attr_encrypted :refresh_token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false
  end
end
