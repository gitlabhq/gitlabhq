module EE
  module Gitlab
    module GeoGitAccess
      include ::EE::GitlabRoutingHelper

      GEO_SERVER_DOCS_URL = 'https://docs.gitlab.com/ee/gitlab-geo/using_a_geo_server.html'.freeze

      private

      def push_to_read_only_message
        message = super

        if ::Gitlab::Geo.primary_node
          clone_url = geo_primary_default_url_to_repo(project_or_wiki)
          message += " Please use the Primary node URL: #{clone_url}. Documentation: #{GEO_SERVER_DOCS_URL}"
        end

        message
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
