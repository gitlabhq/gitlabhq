# frozen_string_literal: true

module SafeUrl
  extend ActiveSupport::Concern

  def safe_url(usernames_whitelist: [])
    return if url.nil?

    uri = URI.parse(url)
    uri.password = '*****' if uri.password
    uri.user = '*****' if uri.user && !usernames_whitelist.include?(uri.user)
    uri.to_s
  rescue URI::Error
  end
end
