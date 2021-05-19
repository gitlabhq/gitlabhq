# frozen_string_literal: true

module Gitlab
  module EtagCaching
    module Router
      class Graphql
        extend EtagCaching::Router::Helpers
        GRAPHQL_ETAG_RESOURCE_HEADER = 'X-GITLAB-GRAPHQL-RESOURCE-ETAG'

        ROUTES = [
          [
            %r(\Apipelines/id/\d+\z),
            'pipelines_graph',
            'continuous_integration'
          ],
          [
            %r(\Apipelines/sha/\w{7,40}\z),
            'ci_editor',
            'pipeline_authoring'
          ]
        ].map(&method(:build_route)).freeze

        def self.match(request)
          return unless request.path_info == graphql_api_path

          graphql_resource = request.headers[GRAPHQL_ETAG_RESOURCE_HEADER]
          return unless graphql_resource

          ROUTES.find { |route| route.match(graphql_resource) }
        end

        def self.cache_key(request)
          [
            request.path,
            request.headers[GRAPHQL_ETAG_RESOURCE_HEADER]
          ].compact.join(':')
        end

        def self.graphql_api_path
          @graphql_api_path ||= Gitlab::Routing.url_helpers.api_graphql_path
        end
        private_class_method :graphql_api_path
      end
    end
  end
end
