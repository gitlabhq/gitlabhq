# frozen_string_literal: true

module Gitlab
  module Metrics
    module RailsSlis
      class << self
        def initialize_request_slis!
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:rails_request, possible_request_labels)
          initialize_rails_request_error_rate
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:graphql_query, possible_graphql_query_labels)
        end

        def request_apdex
          Gitlab::Metrics::Sli::Apdex[:rails_request]
        end

        def request_error_rate
          Gitlab::Metrics::Sli::ErrorRate[:rails_request]
        end

        def graphql_query_apdex
          Gitlab::Metrics::Sli::Apdex[:graphql_query]
        end

        private

        def possible_graphql_query_labels
          ::Gitlab::Graphql::KnownOperations.default.operations.map do |op|
            {
              endpoint_id: op.to_caller_id,
              # We'll be able to correlate feature_category with https://gitlab.com/gitlab-org/gitlab/-/issues/328535
              feature_category: nil,
              query_urgency: op.query_urgency.name
            }
          end
        end

        def possible_request_labels
          possible_controller_labels + possible_api_labels
        end

        def possible_api_labels
          Gitlab::RequestEndpoints.all_api_endpoints.map do |route|
            endpoint_id = API::Base.endpoint_id_for_route(route)
            route_class = route.app.options[:for]
            feature_category = route_class.feature_category_for_app(route.app)
            request_urgency = route_class.urgency_for_app(route.app)

            {
              endpoint_id: endpoint_id,
              feature_category: feature_category,
              request_urgency: request_urgency.name
            }
          end
        end

        def possible_controller_labels
          Gitlab::RequestEndpoints.all_controller_actions.map do |controller, action|
            {
              endpoint_id: controller.endpoint_id_for_action(action),
              feature_category: controller.feature_category_for_action(action),
              request_urgency: controller.urgency_for_action(action).name
            }
          end
        end

        def initialize_rails_request_error_rate
          return unless Feature.enabled?(:gitlab_metrics_error_rate_sli, type: :development)

          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:rails_request, possible_request_labels)
        end
      end
    end
  end
end
