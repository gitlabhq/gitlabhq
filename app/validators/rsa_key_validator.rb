# frozen_string_literal: true

# RsaKeyValidator
#
# Custom validator for RSA private keys.
#
#   class Project < ActiveRecord::Base
#     validates :signing_key, rsa_key: true
#   end
#
class RsaKeyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_rsa_keys?(value)
      record.errors.add(attribute, "contains invalid RSA keys")
    end
  end

  private

  def valid_rsa_keys?(key_or_keys)
    return false unless key_or_keys

    Array(key_or_keys).each { |key_data| OpenSSL::PKey::RSA.new(key_data) }
  rescue OpenSSL::PKey::RSAError
    false
  end
end
