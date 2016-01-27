# HostnameValidator
#
# Custom validator for Hosts.
#
# This is similar to an URI validator, but will make sure no schema or
# path is present, only the domain part.
#
class HostValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_host?(value)
      record.errors.add(attribute, 'must be a valid hostname!')
    end
  end

  private

  def valid_host?(value)
    URI.parse("http://#{value}").host == value
  rescue URI::InvalidURIError
    false
  end
end
