# AddressableUrlValidator
#
# Custom validator for URLs. This is a stricter version of UrlValidator - it also checks
# for using the right protocol, but it actually parses the URL checking for any syntax errors.
# The regex is also different from `URI` as we use `Addressable::URI` here.
#
# By default, only URLs for http, https, ssh, and git protocols will be considered valid.
# Provide a `:protocols` option to configure accepted protocols.
#
# Example:
#
#   class User < ActiveRecord::Base
#     validates :personal_url, addressable_url: true
#
#     validates :ftp_url, addressable_url: { protocols: %w(ftp) }
#
#     validates :git_url, addressable_url: { protocols: %w(http https ssh git) }
#   end
#
class AddressableUrlValidator < ActiveModel::EachValidator
  DEFAULT_OPTIONS = { protocols: %w(http https ssh git) }

  def validate_each(record, attribute, value)
    unless valid_url?(value)
      record.errors.add(attribute, "must be a valid URL")
    end
  end

  private

  def valid_url?(value)
    return false unless value

    valid_protocol?(value) && valid_uri?(value)
  end

  def valid_uri?(value)
    Gitlab::UrlSanitizer.valid?(value)
  end

  def valid_protocol?(value)
    options = DEFAULT_OPTIONS.merge(self.options)
    value =~ /\A#{URI.regexp(options[:protocols])}\z/
  end
end
