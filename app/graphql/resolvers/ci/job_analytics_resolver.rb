# frozen_string_literal: true

module Resolvers
  module Ci
    class JobAnalyticsResolver < BaseResolver
      type ::Types::Ci::JobAnalyticsType.connection_type, null: true

      authorizes_object!
      authorize :read_ci_cd_analytics

      extras [:lookahead]

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

      def resolve(lookahead:, **args)
        nodes = node_selection(lookahead)

        query_builder = ::Ci::JobAnalytics::QueryBuilder.new(
          project: project,
          current_user: current_user,
          options: args.merge(
            select_fields: detect_select_fields(nodes, args[:sort]),
            aggregations: detect_aggregations(nodes, args[:sort])
          )
        ).execute

        raise_resource_not_available_error! if query_builder.nil?

        ::Gitlab::Graphql::Pagination::ClickHouseAggregatedRelation.new(query_builder)
      end

      private

      def project
        object.respond_to?(:sync) ? object.sync : object
      end

      # Detects which fields to SELECT and GROUP BY based on the GraphQL query.
      # Always includes `:name` as the minimum selection because it serves as the
      # primary grouping key for job analytics aggregations in ClickHouse.
      # Without a grouping key, aggregations would collapse all jobs into a single row.
      def detect_select_fields(nodes, sort = nil)
        fields = (nodes.selections.map(&:name) &
          ClickHouse::Finders::Ci::FinishedBuildsFinder::ALLOWED_TO_SELECT).presence || [:name]

        fields | extract_sort_field(sort, select_field: true)
      end

      def detect_aggregations(nodes, sort = nil)
        aggregations = extract_sort_field(sort, select_field: false)

        return aggregations unless nodes.selects?(:statistics)

        nodes.selection(:statistics).then do |statistics|
          aggregations
            .concat(extract_duration_aggregations(statistics))
            .concat(extract_status_aggregations(statistics)) &
            ClickHouse::Finders::Ci::FinishedBuildsFinder::ALLOWED_AGGREGATIONS
        end
      end

      def extract_duration_aggregations(statistics)
        return [] unless statistics.selects?(:duration_statistics)

        statistics.selection(:duration_statistics).selections.map { |field| :"#{field.name}_duration" }
      end

      def extract_status_aggregations(statistics)
        statistics.selections.filter_map do |s|
          status = s.arguments[:status]
          next if status == :other # not supported in UI yet, will be added in followup MRs

          all = status.nil? || status == :any?
          case s.name
          when :count
            all ? :total_count : :"count_#{status}"
          when :rate
            all ? nil : :"rate_of_#{status}"
          end
        end
      end

      # Extracts the sort field and returns it as a single-element array when it matches the requested type.
      # Select fields (e.g. name, stage_name) need to be added to select/group-by,
      # while aggregation fields need to be added to aggregations.
      def extract_sort_field(sort, select_field:)
        return [] unless sort

        field = sort.to_s.sub(/_(?:asc|desc)$/, '').to_sym
        can_select = ClickHouse::Finders::Ci::FinishedBuildsFinder::ALLOWED_TO_SELECT.include?(field)
        return [] unless can_select == select_field

        [field]
      end

      def node_selection(lookahead)
        lookahead.selects?(:edges) ? lookahead.selection(:edges).selection(:node) : lookahead.selection(:nodes)
      end
    end
  end
end
