# frozen_string_literal: true

module Gitlab
  class HotlinkingDetector
    IMAGE_FORMATS = %w[image/jpeg image/apng image/png image/webp image/svg+xml image/*].freeze
    MEDIA_FORMATS = %w[video/webm video/ogg video/* application/ogg audio/webm audio/ogg audio/wav audio/*].freeze
    CSS_FORMATS = %w[text/css].freeze
    INVALID_FORMATS = (IMAGE_FORMATS + MEDIA_FORMATS + CSS_FORMATS).freeze
    INVALID_FETCH_MODES = %w[cors no-cors websocket].freeze

    class << self
      def intercept_hotlinking?(request)
        request_accepts = parse_request_accepts(request)

        # Block attempts to embed as JS
        return true if sec_fetch_invalid?(request)

        # If no Accept header was set, skip the rest
        return false if request_accepts.empty?

        # Workaround for IE8 weirdness
        return false if IMAGE_FORMATS.include?(request_accepts.first) && request_accepts.include?("application/x-ms-application")

        # Block all other media requests if the first format is a media type
        return true if INVALID_FORMATS.include?(request_accepts.first)

        false

      rescue ActionDispatch::Http::MimeNegotiation::InvalidType, Mime::Type::InvalidMimeType
        # Malformed requests with invalid MIME types prevent the checks from
        # being executed correctly, so we should intercept those requests.
        true
      end

      private

      def sec_fetch_invalid?(request)
        fetch_mode = request.headers["Sec-Fetch-Mode"]

        return if fetch_mode.blank?
        return true if INVALID_FETCH_MODES.include?(fetch_mode)
      end

      def parse_request_accepts(request)
        # Rails will already have parsed the Accept header
        return request.accepts if request.respond_to?(:accepts)

        # Grape doesn't parse it, so we can use the Rails system for this
        return Mime::Type.parse(request.headers["Accept"]) if request.respond_to?(:headers) && request.headers["Accept"].present?

        []
      end
    end
  end
end
