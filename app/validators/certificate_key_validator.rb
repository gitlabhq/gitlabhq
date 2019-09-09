# frozen_string_literal: true

# CertificateKeyValidator
#
# Custom validator for private keys.
#
#   class Project < ActiveRecord::Base
#     validates :certificate_key, certificate_key: true
#   end
#
class CertificateKeyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_private_key_pem?(value)
      record.errors.add(attribute, "must be a valid PEM private key")
    end
  end

  private

  def valid_private_key_pem?(value)
    return false unless value

    pkey = OpenSSL::PKey.read(value)
    pkey.private?
  rescue OpenSSL::PKey::PKeyError
    false
  end
end
