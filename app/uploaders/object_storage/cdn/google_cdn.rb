# rubocop:disable Naming/FileName
# frozen_string_literal: true

module ObjectStorage
  module CDN
    class GoogleCDN
      include Gitlab::Utils::StrongMemoize

      attr_reader :options

      def initialize(options)
        @options = HashWithIndifferentAccess.new(options.to_h)

        GoogleIpCache.async_refresh unless GoogleIpCache.ready?
      end

      def use_cdn?(request_ip)
        return false unless config_valid?

        ip = IPAddr.new(request_ip)

        return false if ip.private? || ip.link_local? || ip.loopback?

        !GoogleIpCache.google_ip?(request_ip)
      end

      def signed_url(path, expiry: 10.minutes, params: {})
        expiration = (Time.current + expiry).utc.to_i

        uri = Addressable::URI.parse(cdn_url)
        uri.path = Addressable::URI.encode_component(path, Addressable::URI::CharacterClasses::PATH)
        # Use an Array to preserve order: Google CDN needs to have
        # Expires, KeyName, and Signature in that order or it will return a 403 error:
        # https://cloud.google.com/cdn/docs/troubleshooting-steps#signing
        query_params = params.to_a
        query_params << ['Expires', expiration]
        query_params << ['KeyName', key_name]
        uri.query_values = query_params

        unsigned_url = uri.to_s
        signature = OpenSSL::HMAC.digest('SHA1', decoded_key, unsigned_url)
        encoded_signature = Base64.urlsafe_encode64(signature)

        "#{unsigned_url}&Signature=#{encoded_signature}"
      end

      private

      def config_valid?
        [key_name, decoded_key, cdn_url].all?(&:present?) && cdn_url.start_with?('https://')
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
    end
  end
end

# rubocop:enable Naming/FileName
