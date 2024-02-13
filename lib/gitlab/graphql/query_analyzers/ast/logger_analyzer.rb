# frozen_string_literal: true

module Gitlab
  module Graphql
    module QueryAnalyzers
      module AST
        class LoggerAnalyzer < GraphQL::Analysis::AST::Analyzer
          COMPLEXITY_ANALYZER = GraphQL::Analysis::AST::QueryComplexity
          DEPTH_ANALYZER = GraphQL::Analysis::AST::QueryDepth
          FIELD_USAGE_ANALYZER = GraphQL::Analysis::AST::FieldUsage
          ALL_ANALYZERS = [COMPLEXITY_ANALYZER, DEPTH_ANALYZER, FIELD_USAGE_ANALYZER].freeze

          def initialize(query)
            super

            @results = default_initial_values(query).merge({
              time_started: Gitlab::Metrics::System.monotonic_time
            })
          rescue StandardError => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
            @results = default_initial_values(query_or_multiplex)
          end

          def result
            complexity, depth, field_usages =
              GraphQL::Analysis::AST.analyze_query(@subject, ALL_ANALYZERS, multiplex_analyzers: [])

            results[:depth] = depth
            results[:complexity] = complexity
            # This duration is not the execution time of the
            # query but the execution time of the analyzer.
            results[:duration_s] = duration(results[:time_started])
            results[:used_fields] = field_usages[:used_fields]
            results[:used_deprecated_fields] = field_usages[:used_deprecated_fields]
            results[:used_deprecated_arguments] = field_usages[:used_deprecated_arguments]

            push_to_request_store(results)

            # This gl_analysis is included in the tracer log
            query.context[:gl_analysis] = results.except!(:time_started, :query)
          rescue StandardError => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
          end

          private

          attr_reader :results

          def push_to_request_store(results)
            query = @subject

            # TODO: This RequestStore management is used to handle setting request wide metadata
            # to improve preexisting logging. We should handle this either with ApplicationContext
            # or in a separate tracer.
            # https://gitlab.com/gitlab-org/gitlab/-/issues/343802

            RequestStore.store[:graphql_logs] ||= []
            RequestStore.store[:graphql_logs] << results.except(:time_started, :duration_s).merge({
              variables: process_variables(query.provided_variables),
              operation_name: query.operation_name
            })
          end

          def process_variables(variables)
            filtered_variables = filter_sensitive_variables(variables)
            filtered_variables.try(:to_s) || filtered_variables
          end

          def filter_sensitive_variables(variables)
            ActiveSupport::ParameterFilter
              .new(::Rails.application.config.filter_parameters)
              .filter(variables)
          end

          def duration(time_started)
            Gitlab::Metrics::System.monotonic_time - time_started
          end

          def default_initial_values(query)
            {
              time_started: Gitlab::Metrics::System.monotonic_time,
              duration_s: nil
            }
          end
        end
      end
    end
  end
end
