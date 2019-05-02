# frozen_string_literal: true

module Gitlab
  module Graphql
    module QueryAnalyzers
      class LoggerAnalyzer
        def initialize
          @info_hash = {}
        end

        # Called before initializing the analyzer.
        # Returns true to run this analyzer, or false to skip it.
        def analyze?(query)
          true # unless there's some reason why we wouldn't log?
        end

        # Called before the visit.
        # Returns the initial value for `memo`
        def initial_value(query)
          {
            time_started: Time.zone.now,
            query_string: query.query_string,
            variables: query.provided_variables
          }
        end

        # This is like the `reduce` callback.
        # The return value is passed to the next call as `memo`
        def call(memo, visit_type, irep_node)
          memo
        end

        # Called when we're done the whole visit.
        # The return value may be a GraphQL::AnalysisError (or an array of them).
        # Or, you can use this hook to write to a log, etc
        def final_value(memo)
          memo[:duration] = "#{duration(memo[:time_started]).round(1)}ms"
          set_complexity
          set_depth
          GraphqlLogger.info(memo.except!(:time_started).merge(@info_hash))
          memo
        end

        private

        def set_complexity
          GraphQL::Analysis::QueryComplexity.new do |query, complexity_value|
            @info_hash[:complexity] = complexity_value
          end
        end

        def set_depth
          GraphQL::Analysis::QueryDepth.new do |query, depth_value|
            @info_hash[:depth] = depth_value
          end
        end

        def duration(time_started)
          nanoseconds = Time.zone.now - time_started
          nanoseconds / 1000000
        end
      end
    end
  end
end
