# rubocop:disable Naming/FileName
# frozen_string_literal: true

module ObjectStorage
  module CDN
    class GoogleCDN
      include Gitlab::Utils::StrongMemoize

      IpListNotRetrievedError = Class.new(StandardError)

      GOOGLE_CDN_LIST_KEY = 'google_cdn_ip_list'
      GOOGLE_IP_RANGES_URL = 'https://www.gstatic.com/ipranges/cloud.json'
      EXPECTED_CONTENT_TYPE = 'application/json'
      RESPONSE_BODY_LIMIT = 1.megabyte
      CACHE_EXPIRATION_TIME = 1.day

      attr_reader :options

      def initialize(options)
        @options = HashWithIndifferentAccess.new(options.to_h)
      end

      def use_cdn?(request_ip)
        return false unless config_valid?

        ip = IPAddr.new(request_ip)

        return false if ip.private?
        return false unless google_ip_ranges.present?

        !google_ip?(request_ip)
      end

      def signed_url(path, expiry: 10.minutes)
        expiration = (Time.current + expiry).utc.to_i

        uri = Addressable::URI.parse(cdn_url)
        uri.path = path
        uri.query = "Expires=#{expiration}&KeyName=#{key_name}"

        signature = OpenSSL::HMAC.digest('SHA1', decoded_key, uri.to_s)
        encoded_signature = Base64.urlsafe_encode64(signature)

        uri.query += "&Signature=#{encoded_signature}"
        uri.to_s
      end

      private

      def config_valid?
        [key_name, decoded_key, cdn_url].all?(&:present?)
      end

      def key_name
        strong_memoize(:key_name) do
          options['key_name']
        end
      end

      def decoded_key
        strong_memoize(:decoded_key) do
          Base64.urlsafe_decode64(options['key']) if options['key']
        rescue ArgumentError
          Gitlab::ErrorTracking.log_exception(ArgumentError.new("Google CDN key is not base64-encoded"))
          nil
        end
      end

      def cdn_url
        strong_memoize(:cdn_url) do
          options['url']
        end
      end

      def google_ip?(request_ip)
        google_ip_ranges.any? { |range| range.include?(request_ip) }
      end

      def google_ip_ranges
        strong_memoize(:google_ip_ranges) do
          cache_value(GOOGLE_CDN_LIST_KEY) { fetch_google_ip_list }
        end
      rescue IpListNotRetrievedError => err
        Gitlab::ErrorTracking.log_exception(err)
        []
      end

      def cache_value(key, expires_in: CACHE_EXPIRATION_TIME, &block)
        l1_cache.fetch(key, expires_in: expires_in) do
          l2_cache.fetch(key, expires_in: expires_in) { yield }
        end
      end

      def l1_cache
        Gitlab::ProcessMemoryCache.cache_backend
      end

      def l2_cache
        Rails.cache
      end

      def fetch_google_ip_list
        response = Gitlab::HTTP.get(GOOGLE_IP_RANGES_URL)

        raise IpListNotRetrievedError, "response was #{response.code}" unless response.code == 200

        if response.body&.bytesize.to_i > RESPONSE_BODY_LIMIT
          raise IpListNotRetrievedError, "response was too large: #{response.body.bytesize}"
        end

        parsed_response = response.parsed_response

        unless response.content_type == EXPECTED_CONTENT_TYPE && parsed_response.is_a?(Hash)
          raise IpListNotRetrievedError, "response was not JSON"
        end

        parse_google_prefixes(parsed_response)
      end

      def parse_google_prefixes(parsed_response)
        prefixes = parsed_response['prefixes']

        raise IpListNotRetrievedError, "JSON was type #{prefixes.class}, expected Array" unless prefixes.is_a?(Array)

        ranges = prefixes.map do |prefix|
          ip_range = prefix['ipv4Prefix'] || prefix['ipv6Prefix']

          next unless ip_range

          IPAddr.new(ip_range)
        end.compact

        raise IpListNotRetrievedError, "#{GOOGLE_IP_RANGES_URL} did not return any IP ranges" if ranges.empty?

        ranges
      end
    end
  end
end

# rubocop:enable Naming/FileName
