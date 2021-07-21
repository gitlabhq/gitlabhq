# frozen_string_literal: true

module Metrics
  module Dashboard
    class ScheduleAnnotationsPruneWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :metrics

      idempotent! # PruneOldAnnotationsWorker worker is idempotent in the scope of 24 hours

      def perform
        # Process is split into two jobs to avoid long running jobs, which are more prone to be disrupted
        # mid work, which may cause some data not be delete, especially because cronjobs has retry option disabled
        PruneOldAnnotationsWorker.perform_async
      end
    end
  end
end
