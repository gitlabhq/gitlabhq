# frozen_string_literal: true

module Gitlab
  module Analytics
    module UsageTrends
      class WorkersArgumentBuilder
        def initialize(measurement_identifiers: [], recorded_at: Time.zone.now)
          @measurement_identifiers = measurement_identifiers
          @recorded_at = recorded_at
        end

        def execute
          measurement_identifiers.map do |measurement_identifier|
            query_scope = query_mappings[measurement_identifier]&.call

            next if query_scope.nil?

            [measurement_identifier, *determine_start_and_finish(measurement_identifier, query_scope), recorded_at]
          end.compact
        end

        private

        attr_reader :measurement_identifiers, :recorded_at

        # Determining the query range (id range) as early as possible in order to get more accurate counts.
        def determine_start_and_finish(measurement_identifier, query_scope)
          queries = custom_min_max_queries[measurement_identifier]

          if queries
            [queries[:minimum_query].call, queries[:maximum_query].call]
          else
            [query_scope.minimum(:id), query_scope.maximum(:id)]
          end
        end

        def custom_min_max_queries
          ::Analytics::UsageTrends::Measurement.identifier_min_max_queries
        end

        def query_mappings
          ::Analytics::UsageTrends::Measurement.identifier_query_mapping
        end
      end
    end
  end
end
