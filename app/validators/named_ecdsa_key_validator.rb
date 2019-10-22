# frozen_string_literal: true

# NamedEcdsaKeyValidator
#
# Custom validator for ecdsa private keys.
# Golang currently doesn't support explicit curves for ECDSA certificates
# This validator checks if curve is set by name, not by parameters
#
#   class Project < ActiveRecord::Base
#     validates :certificate_key, named_ecdsa_key: true
#   end
#
class NamedEcdsaKeyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if explicit_ec?(value)
      record.errors.add(attribute, "ECDSA keys with explicit curves are not supported")
    end
  end

  private

  def explicit_ec?(value)
    return false unless value

    pkey = OpenSSL::PKey.read(value)
    return false unless pkey.is_a?(OpenSSL::PKey::EC)

    pkey.group.asn1_flag != OpenSSL::PKey::EC::NAMED_CURVE
  rescue OpenSSL::PKey::PKeyError
    false
  end
end
