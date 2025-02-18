# frozen_string_literal: true

module Analytics
  module UsageTrends
    class CounterJobWorker
      TIMEOUT = 250.seconds

      extend ::Gitlab::Utils::Override
      include ApplicationWorker
      include CronjobChildWorker

      data_consistency :sticky

      sidekiq_options retry: 3

      feature_category :devops_reports
      urgency :low

      idempotent!

      def perform(measurement_identifier, min_id, max_id, recorded_at, partial_results = nil)
        query_scope = ::Analytics::UsageTrends::Measurement.identifier_query_mapping[measurement_identifier].call

        result = counter(query_scope, min_id, max_id, partial_results)

        # If the batch counter timed out, schedule a job to continue counting later
        if result[:status] == :timeout
          return self.class.perform_async(measurement_identifier, result[:continue_from], max_id, recorded_at, result[:partial_results])
        end

        return if result[:status] != :completed

        UsageTrends::Measurement.insert_all([{ recorded_at: recorded_at, count: result[:count], identifier: measurement_identifier }])
      end

      private

      def counter(query_scope, min_id, max_id, partial_results)
        return { status: :completed, count: 0 } if min_id.nil? || max_id.nil? # table is empty

        Gitlab::Database::BatchCount.batch_count_with_timeout(query_scope, start: min_id, finish: max_id, timeout: TIMEOUT, partial_results: partial_results)
      end
    end
  end
end
