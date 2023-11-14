# frozen_string_literal: true

# IpCidrValidator
#
# Validates that an IP is a valid IPv4 or IPv6 CIDR address.
#
# Example:
#
#   class Group < ActiveRecord::Base
#     validates :ip, presence: true, ip_cidr: true
#   end

class IpCidrValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/NamespacedClass -- This is a globally shareable validator, but it's unclear what namespace it should belong in
  def validate_each(record, attribute, value)
    # NOTE: We want this to be usable for nullable fields, so we don't validate presence.
    #       Use a separate `presence` validation for the field if needed.
    return true if value.blank?

    # rubocop:disable Layout/LineLength -- The error message is bigger than the line limit
    unless valid_cidr_format?(value)
      record.errors.add(
        attribute,
        format(_(
          "IP '%{value}' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"),
          value: value
        )
      )
      return
    end
    # rubocop:enable Layout/LineLength

    IPAddress.parse(value)
  rescue ArgumentError => e
    record.errors.add(
      attribute,
      format(_("IP '%{value}' is not a valid CIDR: %{message}"), value: value, message: e.message)
    )
  end

  private

  def valid_cidr_format?(cidr)
    cidr.count('/') == 1 && cidr.split('/').last =~ /^\d+$/
  end
end
