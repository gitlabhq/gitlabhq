# UrlValidator
#
# Custom validator for URLs.
#
# By default, only URLs for the HTTP(S) protocols will be considered valid.
# Provide a `:protocols` option to configure accepted protocols.
#
# Also, this validator can help you validate urls with placeholders inside.
# Usually, if you have a url like 'http://www.example.com/%{project_path}' the
# URI parser will reject that URL format. Provide a `:placeholder_regex` option
# to configure accepted placeholders.
#
# Example:
#
#   class User < ActiveRecord::Base
#     validates :personal_url, url: true
#
#     validates :ftp_url, url: { protocols: %w(ftp) }
#
#     validates :git_url, url: { protocols: %w(http https ssh git) }
#
#     validates :placeholder_url, url: { placeholder_regex: /(project_path|project_id|default_branch)/ }
#   end
#
class UrlPlaceholderValidator < UrlValidator
  def validate_each(record, attribute, value)
    placeholder_regex = self.options[:placeholder_regex]
    value = value.gsub(/%{#{placeholder_regex}}/, 'foo') if placeholder_regex && value

    super(record, attribute, value)
  end
end
