# frozen_string_literal: true

module Metrics
  module Dashboard
    class PruneOldAnnotationsWorker
      include ApplicationWorker

      sidekiq_options retry: 3

      DELETE_LIMIT = 10_000
      DEFAULT_CUT_OFF_PERIOD = 2.weeks

      feature_category :metrics

      idempotent! # in the scope of 24 hours

      def perform
        stale_annotations = ::Metrics::Dashboard::Annotation.ending_before(DEFAULT_CUT_OFF_PERIOD.ago.beginning_of_day)
        stale_annotations.delete_with_limit(DELETE_LIMIT)

        self.class.perform_async if stale_annotations.exists?
      end
    end
  end
end
