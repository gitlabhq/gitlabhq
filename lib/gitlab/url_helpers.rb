# frozen_string_literal: true

module Gitlab
  class UrlHelpers
    WSS_PROTOCOL = "wss"
    def self.as_wss(url)
      return unless url.present?

      URI.parse(url).tap do |uri|
        uri.scheme = WSS_PROTOCOL
      end.to_s
    rescue URI::InvalidURIError
      nil
    end
  end
end
