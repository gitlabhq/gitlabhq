# frozen_string_literal: true

module Gitlab
  module EtagCaching
    module Router
      Route = Struct.new(:router, :regexp, :name, :feature_category, :caller_id) do
        delegate :match, to: :regexp
        delegate :cache_key, to: :router
      end

      module Helpers
        def build_route(attrs)
          EtagCaching::Router::Route.new(self, *attrs)
        end

        def build_rails_route(attrs)
          regexp, name, controller, action_name = *attrs
          EtagCaching::Router::Route.new(
            self,
            regexp,
            name,
            controller.feature_category_for_action(action_name).to_s,
            controller.endpoint_id_for_action(action_name).to_s
          )
        end
      end

      # Performing Rails routing match before GraphQL would be more expensive
      # for the GraphQL requests because we need to traverse all of the RESTful
      # route definitions before falling back to GraphQL.
      def self.match(request)
        Router::Graphql.match(request) || Router::Rails.match(request)
      end
    end
  end
end
