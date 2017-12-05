module EE
  module Gitlab
    module GeoGitAccess
      include ::EE::GitlabRoutingHelper

      GEO_SERVER_DOCS_URL = 'https://docs.gitlab.com/ee/gitlab-geo/using_a_geo_server.html'.freeze

      private

      def push_to_read_only_message
        message = super

        if ::Gitlab::Geo.secondary_with_primary?
          message += " Please use the Primary node URL: #{geo_primary_url_to_repo}. Documentation: #{GEO_SERVER_DOCS_URL}"
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

      def current_user
        user
      end

      def project_or_wiki
        self.class.name == 'Gitlab::GitAccessWiki' ? @project.wiki : @project
      end

      def gitlab_config
        ::Gitlab.config.gitlab
      end
    end
  end
end
