# frozen_string_literal: true

module SafeUrl
  extend ActiveSupport::Concern

  # Return the URL with obfuscated userinfo
  # and keeping it intact
  def safe_url(allowed_usernames: [])
    return if url.nil?

    escaped = Addressable::URI.escape(url)
    uri = URI.parse(escaped)
    password_present = uri.password.present?

    uri.user = '*****' if uri.user && allowed_usernames.exclude?(uri.user)
    uri.password = '*****' if password_present
    Addressable::URI.unescape(uri.to_s)
  rescue URI::Error, TypeError, Addressable::URI::InvalidURIError
  end
end
