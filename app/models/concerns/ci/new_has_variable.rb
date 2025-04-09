# frozen_string_literal: true

module Ci
  module NewHasVariable
    extend ActiveSupport::Concern
    include Ci::HasVariable

    included do
      include Gitlab::EncryptedAttribute

      attr_encrypted :value,
        mode: :per_attribute_iv,
        algorithm: 'aes-256-gcm',
        key: :db_key_base_32,
        insecure_mode: false
    end
  end
end
