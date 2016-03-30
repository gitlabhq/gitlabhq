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
class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless valid_url?(value)
      record.errors.add(attribute, "must be a valid URL")
    end
  end

  private

  def default_options
    @default_options ||= { protocols: %w(http https) }
  end

  def valid_url?(value)
    return false if value.nil?

    options = default_options.merge(self.options)

    value.strip!
    value =~ /\A#{URI.regexp(options[:protocols])}\z/
  end
end
