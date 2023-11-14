# frozen_string_literal: true

# IpCidrArrayValidator
#
# Validates that an array of IP are a valid IPv4 or IPv6 CIDR address.
#
# Example:
#
#   class Group < ActiveRecord::Base
#     validates :ip_array, presence: true, ip_cidr_array: true
#   end

class IpCidrArrayValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/NamespacedClass -- This is a globally shareable validator, but it's unclear what namespace it should belong in
  def validate_each(record, attribute, value)
    unless value.is_a?(Array)
      record.errors.add(attribute, _("must be an array of CIDR values"))
      return
    end

    value.each do |cidr|
      single_validator = IpCidrValidator.new(attributes: attribute)
      single_validator.validate_each(record, attribute, cidr)
    end
  end
end
