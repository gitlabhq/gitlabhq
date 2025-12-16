# frozen_string_literal: true

require 'net/http'

module Observability
  class O11yToken
    AuthenticationError = Class.new(StandardError)
    ConfigurationError = Class.new(StandardError)
    NetworkError = Class.new(StandardError)
    SETUP_BUFFER_TIME = 5.minutes.freeze

    class TokenResponse
      attr_reader :access_jwt, :refresh_jwt

      def self.from_json(data)
        data ||= {}
        new(
          access_jwt: data.dig('data', 'accessToken'),
          refresh_jwt: data.dig('data', 'refreshToken')
        )
      end

      def initialize(access_jwt:, refresh_jwt:)
        @access_jwt = access_jwt
        @refresh_jwt = refresh_jwt
      end

      def to_h
        {
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

      account_id = get_account_id
      return { status: :provisioning } if account_id == :provisioning
      return {} if account_id.blank?

      response = authenticate_user(account_id)
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

    def authenticate_user(account_id)
      http_client.post(login_url, build_payload(account_id))
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      raise NetworkError, "Failed to connect to O11y service (#{e.class.name}): #{e.message}"
    end

    def build_payload(account_id)
      {
        email: o11y_settings.o11y_service_user_email,
        password: o11y_settings.o11y_service_password,
        orgId: account_id
      }
    end

    def login_url
      URI.join(api_url, '/api/v2/sessions/email_password').to_s
    end

    def api_url
      o11y_settings.o11y_service_url
    end

    def get_account_id
      response = http_client.get(account_id_url, context_payload)
      if response.code.to_i != 200
        return :provisioning if response.code.to_i == 500 && new_settings?

        return
      end

      data = Gitlab::Json.parse(response.body)
      data.dig('data', 'orgs', 0, 'id')
    end

    def context_payload
      { email: o11y_settings.o11y_service_user_email }
    end

    def account_id_url
      URI.join(api_url, '/api/v2/sessions/context').to_s
    end

    def parse_response(response)
      if response.code.to_i != 200
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

      def get(url, params = {})
        ::Gitlab::HTTP.get(
          url,
          headers: { 'Content-Type' => 'application/json' },
          allow_local_requests: allow_local_requests?,
          query: params
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
