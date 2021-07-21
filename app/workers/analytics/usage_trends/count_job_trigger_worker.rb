# frozen_string_literal: true

module Analytics
  module UsageTrends
    class CountJobTriggerWorker
      extend ::Gitlab::Utils::Override
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      DEFAULT_DELAY = 3.minutes.freeze

      feature_category :devops_reports
      tags :exclude_from_kubernetes
      urgency :low

      idempotent!

      def perform
        recorded_at = Time.zone.now

        worker_arguments = Gitlab::Analytics::UsageTrends::WorkersArgumentBuilder.new(
          measurement_identifiers: ::Analytics::UsageTrends::Measurement.measurement_identifier_values,
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
