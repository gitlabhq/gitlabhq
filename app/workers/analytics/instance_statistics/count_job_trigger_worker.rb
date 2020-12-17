# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    class CountJobTriggerWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      DEFAULT_DELAY = 3.minutes.freeze

      feature_category :devops_reports
      urgency :low

      idempotent!

      def perform
        recorded_at = Time.zone.now

        worker_arguments = Gitlab::Analytics::InstanceStatistics::WorkersArgumentBuilder.new(
          measurement_identifiers: ::Analytics::InstanceStatistics::Measurement.measurement_identifier_values,
          recorded_at: recorded_at
        ).execute

        perform_in = DEFAULT_DELAY.minutes.from_now
        worker_arguments.each do |args|
          CounterJobWorker.perform_in(perform_in, *args)

          perform_in += DEFAULT_DELAY
        end
      end
    end
  end
end
