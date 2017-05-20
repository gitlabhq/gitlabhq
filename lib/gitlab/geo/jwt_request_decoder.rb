module Gitlab
  module Geo
    InvalidDecryptionKeyError = Class.new(StandardError)

    class JwtRequestDecoder
      IAT_LEEWAY = 60.seconds.to_i

      attr_reader :auth_header

      def initialize(auth_header)
        @auth_header = auth_header
      end

      def decode
        decode_geo_request
      end

      private

      def decode_geo_request
        # A Geo request has an Authorization header:
        # Authorization: GL-Geo: <Geo Access Key>:<JWT payload>
        #
        # For example:
        # JWT payload = { "data": { "oid": "12345" }, iat: 123456 }
        #
        begin
          data = decode_auth_header
        rescue OpenSSL::Cipher::CipherError
          message = 'Error decrypting the Geo secret from the database. Check that the primary and secondary have the same db_key_base.'
          Rails.logger.error(message)
          raise InvalidDecryptionKeyError.new(message)
        end

        return unless data.present?

        secret, encoded_message = data

        begin
          decoded = JWT.decode(
            encoded_message,
            secret,
            true,
            { iat_leeway: IAT_LEEWAY, verify_iat: true, algorithm: 'HS256' }
          )

          message = decoded.first
          data = JSON.parse(message['data']) if message
          data&.deep_symbolize_keys!
          data
        rescue JWT::DecodeError => e
          Rails.logger.error("Error decoding Geo request: #{e}")
          return
        end
      end

      def hmac_secret(access_key)
        @hmac_secret ||= begin
                           geo_node = GeoNode.find_by(access_key: access_key, enabled: true)
                           geo_node&.secret_access_key
                         end
      end

      def decode_auth_header
        return unless auth_header.present?

        tokens = auth_header.split(' ')

        return unless tokens.count == 2
        return unless tokens[0] == Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE

        # Split at the first occurence of a colon
        geo_tokens = tokens[1].split(':', 2)

        return unless geo_tokens.count == 2

        access_key = geo_tokens[0]
        encoded_message = geo_tokens[1]
        secret = hmac_secret(access_key)

        return unless secret.present?

        [secret, encoded_message]
      end
    end
  end
end
