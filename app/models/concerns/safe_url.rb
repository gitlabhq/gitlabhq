# frozen_string_literal: true

module SafeUrl
  extend ActiveSupport::Concern

  # Return the URL with obfuscated userinfo
  # and keeping it intact
  def safe_url(allowed_usernames: [])
    return if url.nil?

    escaped = Addressable::URI.escape(url)
    uri = URI.parse(escaped)
    uri.password = '*****' if uri.password
    uri.user = '*****' if uri.user && allowed_usernames.exclude?(uri.user)
    Addressable::URI.unescape(uri.to_s)
  rescue URI::Error, TypeError
  end
end
