# frozen_string_literal: true

# AddressableUrlValidator
#
# Custom validator for URLs. This is a stricter version of UrlValidator - it also checks
# for using the right protocol, but it actually parses the URL checking for any syntax errors.
# The regex is also different from `URI` as we use `Addressable::URI` here.
#
# By default, only URLs for the HTTP(S) schemes will be considered valid.
# Provide a `:schemes` option to configure accepted schemes.
#
# Example:
#
#   class User < ActiveRecord::Base
#     validates :personal_url, addressable_url: true
#
#     validates :ftp_url, addressable_url: { schemes: %w(ftp) }
#
#     validates :git_url, addressable_url: { schemes: %w(http https ssh git) }
#   end
#
# This validator can also block urls pointing to localhost or the local network to
# protect against Server-side Request Forgery (SSRF), or check for the right port.
#
# Configuration options:
# * <tt>message</tt> - A custom error message (default is: "must be a valid URL").
# * <tt>schemes</tt> - Array of URI schemes. Default: +['http', 'https']+
# * <tt>allow_localhost</tt> - Allow urls pointing to +localhost+. Default: +true+
# * <tt>allow_local_network</tt> - Allow urls pointing to private network addresses. Default: +true+
# * <tt>allow_blank</tt> - Allow urls to be +blank+. Default: +false+
# * <tt>allow_nil</tt> - Allow urls to be +nil+. Default: +false+
# * <tt>ports</tt> - Allowed ports. Default: +all+.
# * <tt>enforce_user</tt> - Validate user format. Default: +false+
# * <tt>enforce_sanitization</tt> - Validate that there are no html/css/js tags. Default: +false+
#
# Example:
#   class User < ActiveRecord::Base
#     validates :personal_url, addressable_url: { allow_localhost: false, allow_local_network: false}
#
#     validates :web_url, addressable_url: { ports: [80, 443] }
#   end
class AddressableUrlValidator < ActiveModel::EachValidator
  attr_reader :record

  # By default, we avoid checking the dns rebinding protection
  # when saving/updating a record. Sometimes, the url
  # is not resolvable at that point, and some automated
  # tasks that uses that url won't work.
  # See https://gitlab.com/gitlab-org/gitlab-ce/issues/66723
  BLOCKER_VALIDATE_OPTIONS = {
    schemes: %w(http https),
    ports: [],
    allow_localhost: true,
    allow_local_network: true,
    ascii_only: false,
    enforce_user: false,
    enforce_sanitization: false,
    dns_rebind_protection: false
  }.freeze

  DEFAULT_OPTIONS = BLOCKER_VALIDATE_OPTIONS.merge({
    message: 'must be a valid URL'
  }).freeze

  def initialize(options)
    options.reverse_merge!(DEFAULT_OPTIONS)

    super(options)
  end

  def validate_each(record, attribute, value)
    @record = record

    unless value.present?
      record.errors.add(attribute, options.fetch(:message))
      return
    end

    value = strip_value!(record, attribute, value)

    Gitlab::UrlBlocker.validate!(value, blocker_args)
  rescue Gitlab::UrlBlocker::BlockedUrlError => e
    record.errors.add(attribute, "is blocked: #{e.message}")
  end

  private

  def strip_value!(record, attribute, value)
    new_value = value.strip
    return value if new_value == value

    record.public_send("#{attribute}=", new_value) # rubocop:disable GitlabSecurity/PublicSend
  end

  def current_options
    options.map do |option, value|
      [option, value.is_a?(Proc) ? value.call(record) : value]
    end.to_h
  end

  def blocker_args
    current_options.slice(*BLOCKER_VALIDATE_OPTIONS.keys).tap do |args|
      if self.class.allow_setting_local_requests?
        args[:allow_localhost] = args[:allow_local_network] = true
      end
    end
  end

  def self.allow_setting_local_requests?
    # We cannot use Gitlab::CurrentSettings as ApplicationSetting itself
    # uses UrlValidator to validate urls. This ends up in a cycle
    # when Gitlab::CurrentSettings creates an ApplicationSetting which then
    # calls this validator.
    #
    # See https://gitlab.com/gitlab-org/gitlab-ee/issues/9833
    ApplicationSetting.current&.allow_local_requests_from_web_hooks_and_services?
  end
end
