# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Chatgpt < OmniAuth::Strategies::OAuth2
      JWKS_URI = 'https://auth.openai.com/.well-known/jwks.json'
      ISSUER = 'https://auth.openai.com'
      JWKS_CACHE_KEY = 'omniauth:chatgpt:jwks'
      JWKS_CACHE_TTL = 1.hour
      CLOCK_SKEW_SECONDS = 30

      IdTokenError = Class.new(StandardError)

      option :name, 'chatgpt'

      option :client_options, {
        site: 'https://auth.openai.com',
        authorize_url: 'https://auth.openai.com/api/accounts/authorize',
        token_url: 'https://auth.openai.com/api/accounts/oauth/token'
      }

      option :pkce, true

      option :authorize_params, {
        scope: 'openid profile email'
      }

      uid do
        raw_info['sub']
      end

      info do
        {
          name: raw_info['name'],
          email: raw_info['email'],
          email_verified: raw_info['email_verified']
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= decode_id_token
      end

      def callback_url
        options[:redirect_uri] || (full_host + callback_path)
      end

      def callback_phase
        super
      rescue IdTokenError => e
        fail! :id_token_error, e
      end

      private

      def decode_id_token
        id_token = access_token.params['id_token']
        raise IdTokenError, 'id_token is missing' unless id_token.present?

        payload, _header = JWT.decode(id_token, nil, true, {
          algorithms: ['RS256'],
          jwks: jwks,
          verify_iss: true,
          iss: ISSUER,
          verify_aud: true,
          aud: options.client_id,
          exp_leeway: CLOCK_SKEW_SECONDS,
          verify_iat: true
        })
        payload || {}
      rescue JWT::DecodeError => e
        Gitlab::AppLogger.error(message: 'ChatGPT id_token decode failed', error_message: e.message)
        raise IdTokenError, e.message
      end

      def jwks
        Rails.cache.fetch(JWKS_CACHE_KEY, expires_in: JWKS_CACHE_TTL, skip_nil: true) do
          fetch_jwks
        end
      end

      def fetch_jwks
        response = Gitlab::HTTP.get(JWKS_URI, timeout: 5)
        return JWT::JWK::Set.new(response.parsed_response) if response.success?

        Gitlab::AppLogger.error(message: 'ChatGPT JWKS fetch failed', status: response.code)
        nil
      rescue *Gitlab::HTTP_V2::HTTP_ERRORS, JSON::ParserError, JWT::JWKError => e
        Gitlab::AppLogger.error(message: 'ChatGPT JWKS fetch failed', error_message: e.message)
        nil
      end
    end
  end
end
