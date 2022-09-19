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

        return false if ip.private?

        !GoogleIpCache.google_ip?(request_ip)
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
    end
  end
end

# rubocop:enable Naming/FileName
