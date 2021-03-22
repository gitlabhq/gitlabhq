# frozen_string_literal: true

module SafeUrl
  extend ActiveSupport::Concern

  def safe_url(allowed_usernames: [])
    return if url.nil?

    uri = URI.parse(url)
    uri.password = '*****' if uri.password
    uri.user = '*****' if uri.user && allowed_usernames.exclude?(uri.user)
    uri.to_s
  rescue URI::Error
  end
end
