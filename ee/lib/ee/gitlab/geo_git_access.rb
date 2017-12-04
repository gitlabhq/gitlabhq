module EE
  module Gitlab
    module GeoGitAccess
      GEO_SERVER_DOCS_URL = 'https://docs.gitlab.com/ee/gitlab-geo/using_a_geo_server.html'.freeze

      private

      def push_to_read_only_message
        message = super

        if ::Gitlab::Geo.primary_node
          primary_url = ActionController::Base.helpers.link_to('primary node', ::Gitlab::Geo.primary_node.url)
          message += " Please use the Primary node URL: #{primary_url.html_safe}. Documentation: #{GEO_SERVER_DOCS_URL}"
        end

        message
      end
    end
  end
end
