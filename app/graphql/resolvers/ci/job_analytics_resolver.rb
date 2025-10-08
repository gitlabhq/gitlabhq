# frozen_string_literal: true

module Resolvers
  module Ci
    class JobAnalyticsResolver < BaseResolver
      type ::Types::Ci::JobAnalyticsType.connection_type, null: true

      authorizes_object!
      authorize :read_ci_cd_analytics

      argument :select_fields,
        [Types::Ci::JobAnalyticsFieldEnum],
        required: true,
        default_value: [:name],
        description: 'Fields to select and group by.'

      argument :aggregations,
        [Types::Ci::JobAnalyticsAggregationEnum],
        required: true,
        default_value: [:mean_duration_in_seconds, :rate_of_failed, :p95_duration_in_seconds],
        description: 'Aggregation functions to apply.'

      argument :name_search,
        GraphQL::Types::String,
        required: false,
        description: 'Search by name of the pipeline jobs. Supports partial matches.'

      argument :sort,
        Types::Ci::JobAnalyticsSortEnum,
        required: false,
        description: 'Sort order for the results.'

      argument :source, Types::Ci::PipelineSourcesEnum,
        required: false,
        description: 'Source of the pipeline.'

      argument :ref, GraphQL::Types::String,
        required: false,
        description: 'Branch that triggered the pipeline.'

      argument :from_time, Types::TimeType,
        required: false,
        description:
          'Start of the requested time (in UTC). Defaults to the pipelines started in the past week.'

      argument :to_time, Types::TimeType,
        required: false,
        description:
          'End of the requested time (in UTC). Defaults to the pipelines started before the current date.'

      def resolve(**args)
        query_builder = ::Ci::JobAnalytics::QueryBuilder.new(
          project: project,
          current_user: current_user,
          options: args
        ).execute

        raise_resource_not_available_error! if query_builder.nil?

        ::Gitlab::Graphql::Pagination::ClickHouseAggregatedRelation.new(query_builder)
      rescue ArgumentError => e
        raise Gitlab::Graphql::Errors::ArgumentError, e.message
      end

      private

      def project
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
