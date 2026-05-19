# frozen_string_literal: true

module Authn
  module IamService
    module RedirectUrlValidator
      module_function

      def valid?(url)
        return false if url.blank?

        parsed = URI.parse(url)
        iam_base = URI.parse(Authn::IamAuthService.url)

        allowed_schemes.include?(parsed.scheme&.downcase) &&
          parsed.host == iam_base.host &&
          parsed.port == iam_base.port
      rescue URI::InvalidURIError
        false
      end

      def allowed_schemes
        Rails.env.development? ? %w[http https] : %w[https]
      end
    end
  end
end
