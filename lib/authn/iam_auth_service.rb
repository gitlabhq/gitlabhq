# frozen_string_literal: true

module Authn
  module IamAuthService
    ConfigurationError = Class.new(StandardError)
    IAM_AUTH_TOKEN_HEADER = 'gitlab-iam-auth-token'

    class << self
      include Gitlab::Utils::StrongMemoize

      def enabled?
        iam_config.enabled
      end

      def url
        http = iam_config.http
        raise ConfigurationError, 'IAM service is not configured' if http.host.blank? || http.port.blank?

        scheme = Rails.env.development? ? 'http' : 'https'
        "#{scheme}://#{http.host}:#{http.port}"
      end

      def jwt_audience
        iam_config.jwt_audience
      end

      def jwt_issuer
        iam_config.jwt_issuer
      end

      def secret
        path = iam_config.secret_file
        raise ConfigurationError, 'IAM auth service secret_file is not configured' if path.blank?

        File.read(path).chomp
      end
      strong_memoize_attr :secret

      private

      def iam_config
        Gitlab.config.iam_auth_service
      end
    end
  end
end
