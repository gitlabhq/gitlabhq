# frozen_string_literal: true

module Gitlab
  module Kas
    INTERNAL_API_AGENTK_REQUEST_HEADER = 'Gitlab-Agentk-Api-Request'
    INTERNAL_API_KAS_REQUEST_HEADER = 'Gitlab-Kas-Api-Request'
    VERSION_FILE = 'GITLAB_KAS_VERSION'
    JWT_ISSUER = 'gitlab-kas'
    JWT_AUDIENCE = 'gitlab'
    K8S_PROXY_PATH = 'k8s-proxy'

    include JwtAuthenticatable

    class << self
      def verify_api_request(request_headers)
        decode_jwt(request_headers[INTERNAL_API_KAS_REQUEST_HEADER], issuer: JWT_ISSUER, audience: JWT_AUDIENCE)
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
        version_info.to_s
      end

      # Return GitLab KAS version info
      #
      # @return [Gitlab::VersionInfo] version_info
      def version_info
        return version_info_from_file if version_info_from_file.valid?

        version_info_from_gitlab_and_file_sha
      end

      # Return GitLab KAS version info for display
      # This is the version that is displayed on the `frontend`. This is also used to
      # check if the version of an existing agent does not match the latest agent version.
      # If the GITLAB_KAS_VERSION file contains a SHA, we defer instead to the Gitlab version.
      #
      # For further details, see: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149794
      #
      # @return [Gitlab::VersionInfo] version_info
      def display_version_info
        return version_info_from_file if version_info_from_file.valid?

        Gitlab.version_info
      end

      # Return GitLab KAS version info for installation
      # This is the version used as the image tag when generating the command to install a Gitlab agent.
      # If the GITLAB_KAS_VERSION file contains a SHA, we defer instead to the Gitlab version without the patch.
      # This could mean that it might point to a Gitlab agent version that is several patches behind the latest one.
      #
      # Further details: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149794
      #
      # @return [Gitlab::VersionInfo] version_info
      def install_version_info
        return version_info_from_file if version_info_from_file.valid?

        Gitlab.version_info.without_patch
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
        uri.scheme = uri.scheme.in?(%w[grpcs wss]) ? 'https' : 'http'
        uri.to_s
      end

      def tunnel_ws_url
        return tunnel_url if ws?
        return tunnel_url.sub('https', 'wss') if ssl?

        tunnel_url.sub('http', 'ws')
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

      def client_timeout_seconds
        Gitlab.config.gitlab_kas&.fetch('client_timeout_seconds', 5) || 5
      end

      private

      def version_file_content
        Rails.root.join(VERSION_FILE).read.chomp
      end

      def version_info_from_file
        Gitlab::VersionInfo.parse(version_file_content, parse_suffix: true)
      end

      def version_info_from_gitlab_and_file_sha
        Gitlab::VersionInfo.parse("#{Gitlab.version_info}+#{version_file_content}", parse_suffix: true)
      end

      def ssl?
        URI(tunnel_url).scheme === 'https'
      end

      def ws?
        URI(tunnel_url).scheme.start_with?('ws')
      end
    end
  end
end
