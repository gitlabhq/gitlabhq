module EE
  module Gitlab
    module GeoGitAccess
      include ::Gitlab::ConfigHelper
      include ::EE::GitlabRoutingHelper
      include GrapePathHelpers::NamedRouteMatcher
      extend ::Gitlab::Utils::Override

      GEO_SERVER_DOCS_URL = 'https://docs.gitlab.com/ee/administration/geo/replication/using_a_geo_server.html'.freeze

      override :check_custom_action
      def check_custom_action(cmd)
        custom_action = custom_action_for(cmd)
        return custom_action if custom_action

        super
      end

      protected

      def project_or_wiki
        @project
      end

      private

      def custom_action_for?(cmd)
        return unless receive_pack?(cmd)
        return unless ::Gitlab::Database.read_only?

        ::Gitlab::Geo.secondary_with_primary?
      end

      def custom_action_for(cmd)
        return unless custom_action_for?(cmd)

        payload = {
          'action' => 'geo_proxy_to_primary',
          'data' => {
            'info_message' => proxying_to_primary_message,
            'api_endpoints' => custom_action_api_endpoints,
            'primary_repo' => primary_http_repo_url
          }
        }

        ::Gitlab::GitAccessResult::CustomAction.new(payload, 'Attempting to proxy to primary.')
      end

      def push_to_read_only_message
        message = super

        if ::Gitlab::Geo.secondary_with_primary?
          message += "\nPlease use the primary node URL instead: #{geo_primary_url_to_repo}.\nFor more information: #{GEO_SERVER_DOCS_URL}"
        end

        message
      end

      def geo_primary_url_to_repo
        case protocol
        when 'ssh'
          geo_primary_ssh_url_to_repo(project_or_wiki)
        else
          geo_primary_http_url_to_repo(project_or_wiki)
        end
      end

      def primary_http_repo_url
        geo_primary_http_url_to_repo(project_or_wiki)
      end

      def primary_ssh_url_to_repo
        geo_primary_ssh_url_to_repo(project_or_wiki)
      end

      def proxying_to_primary_message
        ::Gitlab::Geo::GitPushSSHProxy.inform_client_message(primary_ssh_url_to_repo)
      end

      def custom_action_api_endpoints
        [
          api_v4_geo_proxy_git_push_ssh_info_refs_path,
          api_v4_geo_proxy_git_push_ssh_push_path
        ]
      end
    end
  end
end
