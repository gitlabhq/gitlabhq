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

    # Returns hostname of a URL.
    #
    # @param url [String] URL to parse
    # @return [String|Nilclass] Normalized base URL, or nil if url was unparsable.
    def self.normalized_base_url(url)
      parsed = Utils.parse_url(url)
      return unless parsed

      if parsed.port
        format("%{scheme}://%{host}:%{port}", scheme: parsed.scheme, host: parsed.host, port: parsed.port)
      else
        format("%{scheme}://%{host}", scheme: parsed.scheme, host: parsed.host)
      end
    end
  end
end
