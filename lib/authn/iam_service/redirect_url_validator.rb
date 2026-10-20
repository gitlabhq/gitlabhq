# frozen_string_literal: true

module Authn
  module IamService
    module RedirectUrlValidator
      # /oauth2/authorize goes once gitlab-org/auth/iam!905 is deployed.
      AUTHORIZE_PATHS = %w[/oauth/authorize /oauth2/authorize].freeze

      module_function

      def valid?(url)
        return false if url.blank?

        parsed = URI.parse(url)

        allowed_schemes.include?(parsed.scheme&.downcase) &&
          allowed_origins.any? { |origin| same_origin?(parsed, origin) && authorize_path?(parsed, origin) }
      rescue URI::InvalidURIError
        false
      end

      def same_origin?(parsed, origin)
        parsed.host == origin.host && parsed.port == origin.port
      end

      def authorize_path?(parsed, origin)
        root = origin.path.chomp('/')

        AUTHORIZE_PATHS.any? { |path| parsed.path == root + path }
      end

      # IAM builds its return URLs from its base_url, which on gitlab.com is the
      # instance's own host, while iam_auth_service.http is the IAM workload
      # address Rails uses for JWKS fetches. Both are trusted here.
      def allowed_origins
        [URI.parse(Authn::IamAuthService.url), URI.parse(Gitlab.config.gitlab.url)]
      end

      def allowed_schemes
        Rails.env.development? ? %w[http https] : %w[https]
      end
    end
  end
end
