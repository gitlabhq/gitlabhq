# frozen_string_literal: true

module Gitlab
  module Kas
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Kas-Api-Request'
    JWT_ISSUER = 'gitlab-kas'

    include JwtAuthenticatable

    class << self
      def verify_api_request(request_headers)
        decode_jwt_for_issuer(JWT_ISSUER, request_headers[INTERNAL_API_REQUEST_HEADER])
      rescue JWT::DecodeError
        nil
      end

      def secret_path
        Gitlab.config.gitlab_kas.secret_file
      end

      def ensure_secret!
        return if File.exist?(secret_path)

        write_secret
      end
    end
  end
end
