# frozen_string_literal: true

module Tasks
  module Ci
    class ValidateIdTokenConfigurationTask
      def validate!
        ci_id_token = generate_ci_id_token_for_last_build

        # First decode without verification to get the kid, algorithm and the issuer URL
        decoded_token = decode_jwt_token(ci_id_token)
        kid, algorithm, issuer_url = parse_kid_algorithm_issuer_from_jwt_token(decoded_token)
        open_id_configuration = get_open_id_configuration(issuer_url)

        validate_issuer_configuration!(open_id_configuration: open_id_configuration, id_token_issuer: issuer_url)
        validate_jwks!(open_id_configuration: open_id_configuration, kid: kid)
        verify_jwt_id_token!(id_token: ci_id_token, open_id_configuration: open_id_configuration, algorithm: algorithm,
          kid: kid)
        puts "\n\n\n****** CI ID token configuration is valid ******\n\n\n"
      rescue StandardError => e
        puts "\n\n\n****** CI ID token configuration validation failed : #{e.message} ******\n\n\n"
      end

      private

      def aud_claim
        'test_aud_claim'
      end

      def generate_ci_id_token_for_last_build
        build = ::Ci::Build.last || raise('No CI jobs found. Please run a CI job first')
        ::Gitlab::Ci::JwtV2.for_build(build, aud: aud_claim, sub_components: [])
      end

      def decode_jwt_token(token)
        JWT.decode(token, nil, false)
      end

      def parse_kid_algorithm_issuer_from_jwt_token(decoded_token)
        jwt_payload = decoded_token.first
        jwt_header = decoded_token.last

        kid = jwt_header['kid']
        algorithm = jwt_header['alg']
        ci_id_token_issuer_url = jwt_payload['iss']

        [kid, algorithm, ci_id_token_issuer_url]
      end

      def get_open_id_configuration(issuer_url)
        open_id_configuration_url = "#{issuer_url}/.well-known/openid-configuration"
        ::Gitlab::Json.parse(::Gitlab::HTTP.get(open_id_configuration_url).body)
      rescue JSON::ParserError => e
        raise "Invalid JSON response from #{open_id_configuration_url}: #{e.message}"
      rescue ::Gitlab::HTTP::Error, Timeout::Error, SocketError, OpenSSL::SSL::SSLError => e
        raise "Error while accessing OpenID configuration at #{open_id_configuration_url}: #{e.message}"
      end

      def validate_issuer_configuration!(open_id_configuration:, id_token_issuer:)
        configured_issuer = open_id_configuration['issuer']
        return if configured_issuer == id_token_issuer

        raise "issuer: value incorrectly configured: expected #{id_token_issuer}, got #{configured_issuer}"
      end

      def get_jwks(open_id_configuration)
        jwks_uri = open_id_configuration['jwks_uri']
        ::Gitlab::Json.parse(::Gitlab::HTTP.get(jwks_uri).body)['keys']
      rescue JSON::ParserError => e
        raise "Invalid JSON response from #{jwks_uri}: #{e.message}"
      rescue ::Gitlab::HTTP::Error, Timeout::Error, SocketError, OpenSSL::SSL::SSLError => e
        raise "Error while accessing JWKS URI: #{e.message}"
      end

      def validate_jwks!(open_id_configuration:, kid:)
        jwks = get_jwks(open_id_configuration)
        raise "No JWK found with kid: #{kid} in JWKS" unless jwks.any? { |jwk| jwk['kid'] == kid }
      end

      def get_public_key(open_id_configuration:, kid:)
        jwks = get_jwks(open_id_configuration)
        jwk_key = jwks.find { |jwk| jwk['kid'] == kid }
        JWT::JWK.import(jwk_key).keypair
      end

      def verify_jwt_id_token!(id_token:, open_id_configuration:, algorithm:, kid:)
        public_key = get_public_key(open_id_configuration: open_id_configuration, kid: kid)

        JWT.decode(
          id_token,
          public_key,
          true,
          {
            algorithm: algorithm,
            verify_exp: true,
            verify_iat: true,
            verify_aud: true,
            verify_iss: true,
            aud: aud_claim,
            iss: ::Gitlab.config.ci_id_tokens.issuer_url
          }
        )
      rescue JWT::DecodeError => e
        raise "JWT verification failed: #{e.message}"
      end
    end
  end
end
