# frozen_string_literal: true

module Gitlab
  module Metrics
    module RailsSlis
      class << self
        def initialize_request_slis!
          request_labels = possible_request_labels
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:rails_request, request_labels)
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:rails_request, request_labels)

          graphql_query_labels = possible_graphql_query_labels
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:graphql_query, graphql_query_labels)
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:graphql_query, graphql_query_labels)
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

        def graphql_query_error_rate
          Gitlab::Metrics::Sli::ErrorRate[:graphql_query]
        end

        private

        def possible_graphql_query_labels
          return [] unless Gitlab::Metrics::Environment.api?

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

        def possible_controller_labels
          all_controller_labels.select do |labelset|
            next false if uninitialized_endpoints.member?(labelset[:endpoint_id])

            if known_git_endpoints.include?(labelset[:endpoint_id])
              Gitlab::Metrics::Environment.git?
            else
              Gitlab::Metrics::Environment.web?
            end
          end
        end

        def possible_api_labels
          all_api_labels.select do |labelset|
            next false if uninitialized_endpoints.member?(labelset[:endpoint_id])

            if known_git_endpoints.include?(labelset[:endpoint_id])
              Gitlab::Metrics::Environment.git?
            else
              Gitlab::Metrics::Environment.api?
            end
          end
        end

        def all_api_labels
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

        def all_controller_labels
          Gitlab::RequestEndpoints.all_controller_actions.map do |controller, action|
            {
              endpoint_id: controller.endpoint_id_for_action(action),
              feature_category: controller.feature_category_for_action(action),
              request_urgency: controller.urgency_for_action(action).name
            }
          end
        end

        def known_git_endpoints
          # This is a list of endpoints that endpoints that HAProxy redirects
          # to the git fleet for GitLab.com. It is taken from
          # https://thanos-query.ops.gitlab.net/graph?g0.expr=sum%20by%20(endpoint_id)(sli_aggregations%3Agitlab_sli_rails_request_total_rate6h%7Btype%3D%22git%22%2C%20env%3D%22gprd%22%7D%20%3E%200)&g0.tab=1&g0.stacked=0&g0.range_input=1h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D
          [
            "GET /api/:version/internal/authorized_keys",
            "GET /api/:version/internal/discover",
            "POST /api/:version/internal/allowed",
            "POST /api/:version/internal/lfs_authenticate",
            "POST /api/:version/internal/two_factor_recovery_codes",
            "ProjectsController#show",
            "Repositories::GitHttpController#git_receive_pack",
            "Repositories::GitHttpController#git_upload_pack",
            "Repositories::GitHttpController#info_refs",
            "Repositories::LfsApiController#batch",
            "Repositories::LfsLocksApiController#index",
            "Repositories::LfsLocksApiController#verify",
            "Repositories::LfsStorageController#download",
            "Repositories::LfsStorageController#upload_authorize",
            "Repositories::LfsStorageController#upload_finalize"
          ]
        end

        def uninitialized_endpoints
          @uninitialized_endpoints ||= Set.new(YAML.safe_load(
            File.read(Rails.root.join("lib/gitlab/metrics/rails_slis_uninitialized_endpoints.yml"))
          ))
        end
      end
    end
  end
end
