# frozen_string_literal: true

module Gitlab
  module Graphql
    module QueryAnalyzers
      class LoggerAnalyzer
        COMPLEXITY_ANALYZER = GraphQL::Analysis::QueryComplexity.new { |query, complexity_value| complexity_value }
        DEPTH_ANALYZER = GraphQL::Analysis::QueryDepth.new { |query, depth_value| depth_value }
        FIELD_USAGE_ANALYZER = GraphQL::Analysis::FieldUsage.new { |query, used_fields, used_deprecated_fields| [used_fields, used_deprecated_fields] }
        ALL_ANALYZERS = [COMPLEXITY_ANALYZER, DEPTH_ANALYZER, FIELD_USAGE_ANALYZER].freeze

        def initial_value(query)
          {
            time_started: Gitlab::Metrics::System.monotonic_time,
            query: query
          }
        end

        def call(memo, *)
          memo
        end

        def final_value(memo)
          return if memo.nil?

          query = memo[:query]
          complexity, depth, field_usages = GraphQL::Analysis.analyze_query(query, ALL_ANALYZERS)

          memo[:depth] = depth
          memo[:complexity] = complexity
          # This duration is not the execution time of the
          # query but the execution time of the analyzer.
          memo[:duration_s] = duration(memo[:time_started])
          memo[:used_fields] = field_usages.first
          memo[:used_deprecated_fields] = field_usages.second

          push_to_request_store(memo)

          # This gl_analysis is included in the tracer log
          query.context[:gl_analysis] = memo.except!(:time_started, :query)
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end

        private

        def push_to_request_store(memo)
          query = memo[:query]

          # TODO: This RequestStore management is used to handle setting request wide metadata
          # to improve preexisting logging. We should handle this either with ApplicationContext
          # or in a separate tracer.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/343802

          RequestStore.store[:graphql_logs] ||= []
          RequestStore.store[:graphql_logs] << memo.except(:time_started, :duration_s, :query).merge({
            variables: process_variables(query.provided_variables),
            operation_name: query.operation_name
          })
        end

        def process_variables(variables)
          filtered_variables = filter_sensitive_variables(variables)

          if filtered_variables.respond_to?(:to_s)
            filtered_variables.to_s
          else
            filtered_variables
          end
        end

        def filter_sensitive_variables(variables)
          ActiveSupport::ParameterFilter
            .new(::Rails.application.config.filter_parameters)
            .filter(variables)
        end

        def duration(time_started)
          Gitlab::Metrics::System.monotonic_time - time_started
        end
      end
    end
  end
end
