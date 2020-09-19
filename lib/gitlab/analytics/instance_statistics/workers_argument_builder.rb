# frozen_string_literal: true

module Gitlab
  module Analytics
    module InstanceStatistics
      class WorkersArgumentBuilder
        def initialize(measurement_identifiers: [], recorded_at: Time.zone.now)
          @measurement_identifiers = measurement_identifiers
          @recorded_at = recorded_at
        end

        def execute
          measurement_identifiers.map do |measurement_identifier|
            query_scope = ::Analytics::InstanceStatistics::Measurement::IDENTIFIER_QUERY_MAPPING[measurement_identifier]&.call

            next if query_scope.nil?

            # Determining the query range (id range) as early as possible in order to get more accurate counts.
            start = query_scope.minimum(:id)
            finish = query_scope.maximum(:id)

            [measurement_identifier, start, finish, recorded_at]
          end.compact
        end

        private

        attr_reader :measurement_identifiers, :recorded_at
      end
    end
  end
end
