# frozen_string_literal: true

module Authn
  module IamService
    class AcceptLoginChallengeService
      ACCEPT_PATH = '/oauth2/internal/auth/requests/login/accept'
      TIMEOUT_SECONDS = 5

      def initialize(challenge:, user:)
        @challenge = challenge
        @user = user
      end

      def execute
        response = accept_login_challenge

        unless response.success?
          log_failure(reason: 'http_error', http_status: response.code, response_body: response.body)
          return ServiceResponse.error(
            message: "IAM login accept failed: HTTP #{response.code}",
            reason: :iam_request_failed
          )
        end

        redirect_to = Gitlab::Json.safe_parse(response.body)&.[]('redirect_to')

        error_response = validate_redirect_url(redirect_to)
        return error_response if error_response

        ServiceResponse.success(payload: { redirect_to: redirect_to })
      rescue Authn::IamAuthService::ConfigurationError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      rescue *Gitlab::HTTP_V2::HTTP_ERRORS, JSON::ParserError => e
        Gitlab::ErrorTracking.track_exception(e)
        ServiceResponse.error(message: 'Failed to connect to IAM service', reason: :service_unavailable)
      end

      private

      def accept_login_challenge
        Gitlab::HTTP.put(
          accept_url,
          body: request_body.to_json,
          headers: { 'Content-Type' => 'application/json',
                     Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => Authn::IamAuthService.secret },
          timeout: TIMEOUT_SECONDS
        )
      end

      def validate_redirect_url(redirect_to)
        if redirect_to.blank?
          log_failure(reason: 'missing_redirect_to')
          return ServiceResponse.error(
            message: 'IAM login accept response missing redirect_to',
            reason: :invalid_response
          )
        end

        return if valid_redirect_url?(redirect_to)

        log_failure(reason: 'invalid_redirect_url')
        ServiceResponse.error(
          message: 'IAM login accept response contains invalid redirect URL',
          reason: :invalid_redirect_url
        )
      end

      def accept_url
        uri = URI.parse(Authn::IamAuthService.url)
        uri.path = ACCEPT_PATH
        uri.query = URI.encode_www_form(challenge: @challenge)
        uri.to_s
      end

      def request_body
        {
          id: @user.id.to_s,
          subject: @user.id.to_s,
          name: @user.name,
          email: @user.email
        }
      end

      def valid_redirect_url?(url)
        parsed_uri = URI.parse(url)
        iam_base = URI.parse(Authn::IamAuthService.url)

        allowed_schemes = Rails.env.development? ? %w[http https] : %w[https]
        allowed_schemes.include?(parsed_uri.scheme&.downcase) &&
          parsed_uri.host == iam_base.host &&
          parsed_uri.port == iam_base.port
      rescue URI::InvalidURIError
        false
      end

      def log_failure(reason:, http_status: nil, response_body: nil)
        Gitlab::AuthLogger.error(
          message: 'IAM login challenge accept failed',
          reason: reason,
          Labkit::Fields::GL_USER_ID => @user.id,
          Labkit::Fields::HTTP_STATUS_CODE => http_status,
          iam_login_response_body: response_body&.truncate(100)
        )
      end
    end
  end
end
