# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      class ScopeInputType < BaseInputObject
        graphql_name 'AggregationScopeInput'

        # Shared limit for the combined number of requested groups and projects.
        MAX_SOURCES = 20

        argument :group_full_paths, [GraphQL::Types::ID],
          required: false,
          description: 'Full paths of groups to aggregate data for. Combined with ' \
            "`projectFullPaths`, at most #{MAX_SOURCES} sources can be requested."

        argument :project_full_paths, [GraphQL::Types::ID],
          required: false,
          description: 'Full paths of projects to aggregate data for. Combined with ' \
            "`groupFullPaths`, at most #{MAX_SOURCES} sources can be requested."

        def prepare
          paths = (Array(self[:group_full_paths]) + Array(self[:project_full_paths])).uniq(&:downcase)

          if paths.size > MAX_SOURCES
            raise ::Gitlab::Graphql::Errors::ArgumentError,
              "groupFullPaths and projectFullPaths arguments combined must not exceed #{MAX_SOURCES}"
          end

          super
        end
      end
    end
  end
end
