# frozen_string_literal: true

module Analytics
  module UsageTrends
    class CounterJobWorker
      extend ::Gitlab::Utils::Override
      include ApplicationWorker

      sidekiq_options retry: 3

      feature_category :devops_reports
      urgency :low
      tags :exclude_from_kubernetes

      idempotent!

      def perform(measurement_identifier, min_id, max_id, recorded_at)
        query_scope = ::Analytics::UsageTrends::Measurement.identifier_query_mapping[measurement_identifier].call

        count = if min_id.nil? || max_id.nil? # table is empty
                  0
                else
                  counter(query_scope, min_id, max_id)
                end

        return if count == Gitlab::Database::BatchCounter::FALLBACK

        UsageTrends::Measurement.insert_all([{ recorded_at: recorded_at, count: count, identifier: measurement_identifier }])
      end

      private

      def counter(query_scope, min_id, max_id)
        Gitlab::Database::BatchCount.batch_count(query_scope, start: min_id, finish: max_id)
      end
    end
  end
end
