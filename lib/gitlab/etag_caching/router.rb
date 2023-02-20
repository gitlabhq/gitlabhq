# frozen_string_literal: true

module Gitlab
  module EtagCaching
    module Router
      Route = Struct.new(:router, :regexp, :name, :feature_category, :caller_id, :urgency, keyword_init: true) do
        delegate :match, to: :regexp
        delegate :cache_key, to: :router
      end

      module Helpers
        def build_graphql_route(regexp, name, feature_category)
          EtagCaching::Router::Route.new(
            router: self,
            regexp: regexp,
            name: name,
            feature_category: feature_category,
            # This information can be loaded from the graphql query, but is not
            # included yet
            # https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/665
            caller_id: nil,
            urgency: Gitlab::EndpointAttributes::DEFAULT_URGENCY
          )
        end

        def build_rails_route(regexp, name, controller, action_name)
          EtagCaching::Router::Route.new(
            router: self,
            regexp: regexp,
            name: name,
            feature_category: controller.feature_category_for_action(action_name).to_s,
            caller_id: controller.endpoint_id_for_action(action_name).to_s,
            urgency: controller.urgency_for_action(action_name)
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
