# frozen_string_literal: true

module Metrics
  module Dashboard
    class ScheduleAnnotationsPruneWorker
      include ApplicationWorker

      data_consistency :always

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :metrics

      idempotent! # PruneOldAnnotationsWorker worker is idempotent in the scope of 24 hours

      def perform; end
    end
  end
end
