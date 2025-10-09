# frozen_string_literal: true

require 'net/http'

module Observability
  class O11yToken
    AuthenticationError = Class.new(StandardError)
    ConfigurationError = Class.new(StandardError)
    NetworkError = Class.new(StandardError)
    SETUP_BUFFER_TIME = 5.minutes.freeze

    class TokenResponse
      attr_reader :user_id, :access_jwt, :refresh_jwt

      def self.from_json(data)
        data ||= {}
        new(
          user_id: data.dig('data', 'userId'),
          access_jwt: data.dig('data', 'accessJwt'),
          refresh_jwt: data.dig('data', 'refreshJwt')
        )
      end

      def initialize(user_id:, access_jwt:, refresh_jwt:)
        @user_id = user_id
        @access_jwt = access_jwt
        @refresh_jwt = refresh_jwt
      end

      def to_h
        {
          userId: user_id,
          accessJwt: access_jwt,
          refreshJwt: refresh_jwt
        }
      end
    end

    def self.generate_tokens(o11y_settings)
      new(o11y_settings).generate_tokens
    end

    def initialize(o11y_settings)
      @o11y_settings = o11y_settings
      @http_client = HttpClient.new
    end

    def generate_tokens
      validate_settings!

      response = authenticate_user
      parse_response(response)
    rescue ConfigurationError, AuthenticationError, NetworkError => e
      Gitlab::ErrorTracking.log_exception(e)
      {}
    end

    private

    attr_reader :o11y_settings, :http_client

    def validate_settings!
      raise ConfigurationError, "O11y settings are not set" if o11y_settings.blank?

      raise ConfigurationError, "o11y_service_url is not configured" if o11y_settings.o11y_service_url.blank?

      if o11y_settings.o11y_service_user_email.blank?
        raise ConfigurationError,
          "o11y_service_user_email is not configured"
      end

      raise ConfigurationError, "o11y_service_password is not configured" if o11y_settings.o11y_service_password.blank?
    end

    def authenticate_user
      payload = build_payload
      http_client.post(login_url, payload)
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      raise NetworkError, "Failed to connect to O11y service (#{e.class.name}): #{e.message}"
    end

    def build_payload
      {
        email: o11y_settings.o11y_service_user_email,
        password: o11y_settings.o11y_service_password
      }
    end

    def login_url
      URI.join(o11y_settings.o11y_service_url, '/api/v1/login').to_s
    end

    def parse_response(response)
      if response.code.to_i != 200
        return { status: :provisioning } if response.code.to_i == 500 && new_settings?

        Gitlab::AppLogger.warn("O11y authentication failed with status #{response.code}")
        return {}
      end

      response_body = response.body.to_s.strip
      raise AuthenticationError, "Empty response from O11y service" if response_body.blank?

      data = Gitlab::Json.parse(response.body)
      TokenResponse.from_json(data).to_h
    rescue JSON::ParserError => e
      raise AuthenticationError, "Invalid response format from O11y service: #{e.message}"
    end

    def new_settings?
      o11y_settings.created_at > SETUP_BUFFER_TIME.ago
    end

    class HttpClient
      def post(url, payload)
        ::Gitlab::HTTP.post(
          url,
          headers: { 'Content-Type' => 'application/json' },
          body: Gitlab::Json.dump(payload),
          allow_local_requests: allow_local_requests?
        )
      end

      private

      def allow_local_requests?
        Rails.env.development? ||
          Rails.env.test? ||
          ::Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
      end
    end
  end
end
