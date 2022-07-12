# frozen_string_literal: true

module Ci
  module Runners
    class ReconcileExistingRunnerVersionsCronWorker
      include ApplicationWorker

      # This worker does not schedule other workers that require context.
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      data_consistency :sticky
      feature_category :runner_fleet
      urgency :low

      idempotent!

      def perform
        result = ::Ci::Runners::ReconcileExistingRunnerVersionsService.new.execute
        result.each { |key, value| log_extra_metadata_on_done(key, value) }
      end
    end
  end
end
