module EE
  module Gitlab
    module GeoGitAccess
      include ::EE::GitlabRoutingHelper

      GEO_SERVER_DOCS_URL = 'https://docs.gitlab.com/ee/gitlab-geo/using_a_geo_server.html'.freeze

      private

      def push_to_read_only_message
        message = super

        if ::Gitlab::Geo.primary_node
          clone_url = geo_primary_default_url_to_repo(@project)
          message += " Please use the Primary node URL: #{clone_url}. Documentation: #{GEO_SERVER_DOCS_URL}"
        end

        message
      end

      alias_method :current_user, :user
    end
  end
end
