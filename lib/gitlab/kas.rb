# frozen_string_literal: true

module Gitlab
  module Kas
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Kas-Api-Request'
    VERSION_FILE = 'GITLAB_KAS_VERSION'
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

      # Return GitLab KAS version
      #
      # @return [String] version
      def version
        @_version ||= Rails.root.join(VERSION_FILE).read.chomp
      end

      # Return GitLab KAS external_url
      #
      # @return [String] external_url
      def external_url
        Gitlab.config.gitlab_kas.external_url
      end

      # Return GitLab KAS internal_url
      #
      # @return [String] internal_url
      def internal_url
        Gitlab.config.gitlab_kas.internal_url
      end

      # Return whether GitLab KAS is enabled
      #
      # @return [Boolean] external_url
      def enabled?
        !!Gitlab.config['gitlab_kas']&.fetch('enabled', false)
      end
    end
  end
end
