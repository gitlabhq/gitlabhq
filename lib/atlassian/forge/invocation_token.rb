# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- reuse the existing Atlassian module namespace
module Atlassian
  module Forge
    # Verifies an Atlassian Forge Invocation Token (FIT): an RS256 JWT sent as a
    # bearer token on every Forge Remote call, checked against the Forge JWKS.
    # See https://developer.atlassian.com/platform/forge/remote/essentials/
    class InvocationToken
      include Gitlab::Utils::StrongMemoize

      ALGORITHM = 'RS256'

      # Fixed `iss` for every FIT; signature + audience are the real controls.
      ISSUER = 'forge/invocation-token'

      # A blank audience skips the `aud` check (e.g. before the app id is
      # configured); signature, issuer and expiry still apply.
      def initialize(token, audience:, jwks_client: Atlassian::Forge::JwksClient.new)
        @token = token
        @audience = audience
        @jwks_client = jwks_client
      end

      def valid?
        claims.present?
      end

      def installation_id
        dig_claim('app', 'installationId')
      end

      def cloud_id
        dig_claim('context', 'cloudId')
      end

      def app_id
        dig_claim('app', 'id')
      end

      # Tenant-scoped Jira REST base, e.g. https://api.atlassian.com/ex/jira/<cloudId>.
      def api_base_url
        dig_claim('app', 'apiBaseUrl')
      end

      def module_type
        dig_claim('app', 'module', 'type')
      end

      def module_key
        dig_claim('app', 'module', 'key')
      end

      def principal
        dig_claim('principal')
      end

      private

      attr_reader :token, :audience, :jwks_client

      def claims
        kid = unverified_kid
        return if kid.blank?

        key = jwks_client.verification_key_for(kid)
        return unless key

        JWT.decode(token, key, true, decode_options).first
      rescue JWT::DecodeError, JwksClient::KeyNotFoundError, JwksClient::JwksFetchFailedError => e
        Gitlab::ErrorTracking.track_exception(e)
        nil
      end
      strong_memoize_attr :claims

      def decode_options
        options = {
          algorithm: ALGORITHM,
          verify_expiration: true,
          verify_iss: true,
          iss: ISSUER
        }

        if audience.present?
          options[:verify_aud] = true
          options[:aud] = audience
        end

        options
      end

      def unverified_kid
        _, header = JWT.decode(token, nil, false)
        header['kid']
      rescue JWT::DecodeError
        nil
      end

      def dig_claim(*path)
        claims&.dig(*path)
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
