# frozen_string_literal: true

module Gitlab
  module EtagCaching
    module Router
      Route = Struct.new(:regexp, :name, :feature_category, :router) do
        delegate :match, to: :regexp
        delegate :cache_key, to: :router
      end

      module Helpers
        def build_route(attrs)
          EtagCaching::Router::Route.new(*attrs, self)
        end
      end

      # Performing RESTful routing match before GraphQL would be more expensive
      # for the GraphQL requests because we need to traverse all of the RESTful
      # route definitions before falling back to GraphQL.
      def self.match(request)
        Router::Graphql.match(request) || Router::Restful.match(request)
      end
    end
  end
end
