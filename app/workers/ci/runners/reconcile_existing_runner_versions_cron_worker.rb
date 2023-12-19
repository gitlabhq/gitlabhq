# frozen_string_literal: true

module Ci
  module Runners
    class ReconcileExistingRunnerVersionsCronWorker
      include ApplicationWorker

      # This worker does not schedule other workers that require context.
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      data_consistency :sticky
      feature_category :fleet_visibility
      urgency :low

      deduplicate :until_executed
      idempotent!

      def perform(cronjob_scheduled = true)
        if cronjob_scheduled
          # Introduce some randomness across the day so that instances don't all hit the GitLab Releases API
          # around the same time of day
          period = rand(0..12.hours.in_seconds)
          self.class.perform_in(period, false)

          Sidekiq.logger.info(
            class: self.class.name,
            message: "rescheduled job for #{period.seconds.from_now}")

          return
        end

        result = ::Ci::Runners::ReconcileExistingRunnerVersionsService.new.execute
        log_hash_metadata_on_done(result.payload)
      end
    end
  end
end
