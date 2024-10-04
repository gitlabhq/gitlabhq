# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      # The purpose of this analyzer is to log query activity that contains `IN` clauses having more that 2500 items
      # as this type of query can cause performance degradation in the database.
      #
      # The feature flag should prevent sampling going above 1% or 0.01% of queries hitting
      # to avoid performance issues
      class LogLargeInLists < Base
        MIN_QUERY_SIZE = 10_000
        IN_SIZE_LIMIT = 2_500
        REGEX = /\bIN\s*\((?:\s*\$?\d+\s*,){#{IN_SIZE_LIMIT - 1},}\s*\$?\d+\s*\)/i
        EVENT_NAMES = %w[load pluck].freeze

        EXCLUDE_FROM_TRACE = %w[
          lib/gitlab/database/query_analyzer.rb
          lib/gitlab/database/query_analyzers/log_large_in_lists.rb
        ].freeze

        class << self
          def enabled?
            ::Feature::FlipperFeature.table_exists? &&
              Feature.enabled?(:log_large_in_list_queries, type: :ops)
          end

          # Skips queries containing less than 10000 chars or any other events than +load+ and +pluck+
          def requires_tracking?(parsed)
            return false if parsed.raw.size < MIN_QUERY_SIZE

            EVENT_NAMES.include?(parsed.event_name)
          end

          def analyze(parsed)
            result = check_argument_size(parsed.raw)

            log(result, parsed.event_name) if result.any?
          end

          private

          def check_argument_size(raw)
            matches = raw.scan(REGEX).flatten

            return [] if matches.empty?

            matches.filter_map do |match|
              match_size = match.split(',').size

              match_size if match_size > IN_SIZE_LIMIT
            end
          end

          def log(result, event_name)
            Gitlab::AppLogger.warn(
              message: 'large_in_list_found',
              matches: result.size,
              event_name: event_name,
              in_list_size: result.join(', '),
              stacktrace: backtrace.first(5)
            )
          end

          def backtrace
            Gitlab::BacktraceCleaner.clean_backtrace(caller).reject do |line|
              EXCLUDE_FROM_TRACE.any? { |exclusion| line.include?(exclusion) }
            end
          end
        end
      end
    end
  end
end
