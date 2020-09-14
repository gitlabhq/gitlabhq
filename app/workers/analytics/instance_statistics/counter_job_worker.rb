# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    class CounterJobWorker
      include ApplicationWorker

      feature_category :instance_statistics
      urgency :low

      idempotent!

      def perform(measurement_identifier, min_id, max_id, recorded_at)
        query_scope = ::Analytics::InstanceStatistics::Measurement::IDENTIFIER_QUERY_MAPPING[measurement_identifier].call

        count = if min_id.nil? || max_id.nil? # table is empty
                  0
                else
                  Gitlab::Database::BatchCount.batch_count(query_scope, start: min_id, finish: max_id)
                end

        return if count == Gitlab::Database::BatchCounter::FALLBACK

        InstanceStatistics::Measurement.insert_all([{ recorded_at: recorded_at, count: count, identifier: measurement_identifier }])
      end
    end
  end
end
