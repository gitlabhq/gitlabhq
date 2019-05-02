# frozen_string_literal: true

module Gitlab
  module Graphql
    module QueryAnalyzers
      class LoggerAnalyzer
        # Called before initializing the analyzer.
        # Returns true to run this analyzer, or false to skip it.
        def analyze?(query)
          true # unless there's some reason why we wouldn't log?
        end

        # Called before the visit.
        # Returns the initial value for `memo`
        def initial_value(query)
          {
            time_started: Gitlab::Metrics::System.monotonic_time,
            query_string: query.query_string,
            variables: process_variables(query.provided_variables),
            complexity: nil,
            depth: nil,
            duration: nil
          }
        end

        # This is like the `reduce` callback.
        # The return value is passed to the next call as `memo`
        def call(memo, visit_type, irep_node)
          memo = set_complexity(memo)
          set_depth(memo)
        end

        # Called when we're done the whole visit.
        # The return value may be a GraphQL::AnalysisError (or an array of them).
        # Or, you can use this hook to write to a log, etc
        def final_value(memo)
          memo[:duration] = "#{duration(memo[:time_started]).round(1)}ms"
          GraphqlLogger.info(memo.except!(:time_started))
          memo
        end

        private

        def process_variables(variables)
          if variables.respond_to?(:to_unsafe_h)
            variables.to_unsafe_h
          else
            variables
          end
        end

        def set_complexity(memo)
          GraphQL::Analysis::QueryComplexity.new do |query, complexity_value|
            memo[:complexity] = complexity_value
          end
          memo
        end

        def set_depth(memo)
          GraphQL::Analysis::QueryDepth.new do |query, depth_value|
            memo[:depth] = depth_value
          end
          memo
        end

        def duration(time_started)
          nanoseconds = Gitlab::Metrics::System.monotonic_time - time_started
          nanoseconds * 1000000
        end
      end
    end
  end
end
