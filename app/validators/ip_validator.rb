#            format: { with: ,
#                      message: 'allows only valid IP addresses' }
#
# IpValidator
#
class IpValidator < ActiveModel::EachValidator
  PATTERN = /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/.freeze

  def self.valid?(value)
    !!(value =~ PATTERN)
  end

  def validate_each(record, attribute, value)
    unless self.class.valid?(value)
      record.errors.add(attribute, options[:message] || :invalid)
    end
  end
end
