# frozen_string_literal: true

module Gitlab
  module Graphql
    module QueryAnalyzers
      class LoggerAnalyzer
        COMPLEXITY_ANALYZER = GraphQL::Analysis::QueryComplexity.new { |query, complexity_value| complexity_value }
        DEPTH_ANALYZER = GraphQL::Analysis::QueryDepth.new { |query, depth_value| depth_value }

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
          memo
        end

        def final_value(memo)
          return if memo.nil?

          analyzers = [COMPLEXITY_ANALYZER, DEPTH_ANALYZER]
          complexity, depth = GraphQL::Analysis.analyze_query(memo[:query], analyzers)

          memo[:depth] = depth
          memo[:complexity] = complexity
          memo[:duration] = duration(memo[:time_started]).round(1)

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
          nanoseconds = Gitlab::Metrics::System.monotonic_time - time_started
          nanoseconds * 1000000
        end

        def default_initial_values(query)
          {
            time_started: Gitlab::Metrics::System.monotonic_time,
            query_string: nil,
            query: query,
            variables: nil,
            duration: nil
          }
        end
      end
    end
  end
end
