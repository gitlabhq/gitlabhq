# frozen_string_literal: true

module Gitlab
  module Graphql
    module QueryAnalyzers
      class LoggerAnalyzer
        def analyze?(query)
          Feature.enabled?(:graphql_logging, default_enabled: true)
        end

        def initial_value(query)
          {
            time_started: Gitlab::Metrics::System.monotonic_time,
            query_string: query.query_string,
            query: query,
            variables: process_variables(query.provided_variables),
            duration: nil
          }
        end

        def call(memo, visit_type, irep_node)
          memo
        end

        def final_value(memo)
          analyzers = [complexity_analyzer, depth_analyzer]
          complexity, depth = GraphQL::Analysis.analyze_query(memo[:query], analyzers)

          memo[:depth] = depth
          memo[:complexity] = complexity
          memo[:duration] = duration(memo[:time_started]).round(1)

          GraphqlLogger.info(memo.except!(:time_started, :query))
        end

        private

        def process_variables(variables)
          if variables.respond_to?(:to_json)
            variables.to_json
          else
            variables
          end
        end

        def complexity_analyzer
          GraphQL::Analysis::QueryComplexity.new do |query, complexity_value|
            complexity_value
          end
        end

        def depth_analyzer
          GraphQL::Analysis::QueryDepth.new do |query, depth_value|
            depth_value
          end
        end

        def duration(time_started)
          nanoseconds = Gitlab::Metrics::System.monotonic_time - time_started
          nanoseconds * 1000000
        end
      end
    end
  end
end
