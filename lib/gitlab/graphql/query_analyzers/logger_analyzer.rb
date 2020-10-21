# frozen_string_literal: true

module Gitlab
  module Graphql
    module QueryAnalyzers
      class LoggerAnalyzer
        COMPLEXITY_ANALYZER = GraphQL::Analysis::QueryComplexity.new { |query, complexity_value| complexity_value }
        DEPTH_ANALYZER = GraphQL::Analysis::QueryDepth.new { |query, depth_value| depth_value }
        FIELD_USAGE_ANALYZER = GraphQL::Analysis::FieldUsage.new { |query, used_fields, used_deprecated_fields| [used_fields, used_deprecated_fields] }
        ALL_ANALYZERS = [COMPLEXITY_ANALYZER, DEPTH_ANALYZER, FIELD_USAGE_ANALYZER].freeze

        def analyze?(query)
          Feature.enabled?(:graphql_logging, default_enabled: true)
        end

        def initial_value(query)
          variables = process_variables(query.provided_variables)
          default_initial_values(query).merge({
            query_string: query.query_string,
            variables: variables
          })
        rescue => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
          default_initial_values(query)
        end

        def call(memo, visit_type, irep_node)
          RequestStore.store[:graphql_logs] = memo
        end

        def final_value(memo)
          return if memo.nil?

          complexity, depth, field_usages = GraphQL::Analysis.analyze_query(memo[:query], ALL_ANALYZERS)

          memo[:depth] = depth
          memo[:complexity] = complexity
          # This duration is not the execution time of the
          # query but the execution time of the analyzer.
          memo[:duration_s] = duration(memo[:time_started]).round(1)
          memo[:used_fields] = field_usages.first
          memo[:used_deprecated_fields] = field_usages.second

          GraphqlLogger.info(memo.except!(:time_started, :query))
        rescue => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end

        private

        def process_variables(variables)
          if variables.respond_to?(:to_s)
            variables.to_s
          else
            variables
          end
        end

        def duration(time_started)
          Gitlab::Metrics::System.monotonic_time - time_started
        end

        def default_initial_values(query)
          {
            time_started: Gitlab::Metrics::System.monotonic_time,
            query_string: nil,
            query: query,
            variables: nil,
            duration_s: nil
          }
        end
      end
    end
  end
end
