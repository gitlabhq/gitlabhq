# UrlValidator
#
# Custom validator for URLs.
#
# By default, only URLs for the HTTP(S) protocols will be considered valid.
# Provide a `:protocols` option to configure accepted protocols.
#
# Example:
#
#   class User < ActiveRecord::Base
#     validates :personal_url, url: true
#
#     validates :ftp_url, url: { protocols: %w(ftp) }
#
#     validates :git_url, url: { protocols: %w(http https ssh git) }
#   end
#
class AddressableUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_url?(value)
      record.errors.add(attribute, "must be a valid URL")
    end
  end

  private

  def default_options
    @default_options ||= { protocols: %w(http https ssh git) }
  end

  def valid_url?(value)
    return false unless value

    value.strip!

    valid_uri?(value) && valid_protocol?(value)
  rescue Addressable::URI::InvalidURIError
    false
  end

  def valid_uri?(value)
    Addressable::URI.parse(strip).is_a?(Addressable::URI)
  end

  def valid_protocol?(value)
    options = default_options.merge(self.options)
    value =~ /\A#{URI.regexp(options[:protocols])}\z/
  end
end
