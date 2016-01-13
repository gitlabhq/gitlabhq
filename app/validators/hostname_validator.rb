# HostnameValidator
#
# Custom validator for Hostnames.
#
# This is similar to an URI validator, but will make sure no schema or
# path is present, only the domain part.
#
class HostnameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_hostname?(value)
      record.errors.add(attribute, 'must be a valid host')
    end
  end

  private

  def valid_hostname?(value)
    URI.parse("fake://#{value}").hostname == value
  end
end
