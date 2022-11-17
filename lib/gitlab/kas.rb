# frozen_string_literal: true

module Gitlab
  module Kas
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Kas-Api-Request'
    VERSION_FILE = 'GITLAB_KAS_VERSION'
    JWT_ISSUER = 'gitlab-kas'
    K8S_PROXY_PATH = 'k8s-proxy'

    include JwtAuthenticatable

    class << self
      def verify_api_request(request_headers)
        decode_jwt(request_headers[INTERNAL_API_REQUEST_HEADER], issuer: JWT_ISSUER)
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

      def version_info
        Gitlab::VersionInfo.parse(version, parse_suffix: true)
      end

      # Return GitLab KAS external_url
      #
      # @return [String] external_url
      def external_url
        Gitlab.config.gitlab_kas.external_url
      end

      def tunnel_url
        configured = Gitlab.config.gitlab_kas['external_k8s_proxy_url']
        return configured if configured.present?

        # Legacy code path. Will be removed when all distributions provide a sane default here
        uri = URI.join(external_url, K8S_PROXY_PATH)
        uri.scheme = uri.scheme.in?(%w(grpcs wss)) ? 'https' : 'http'
        uri.to_s
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
