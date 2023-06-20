# frozen_string_literal: true

module Metrics
  module Dashboard
    class PruneOldAnnotationsWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      DELETE_LIMIT = 10_000
      DEFAULT_CUT_OFF_PERIOD = 2.weeks

      feature_category :metrics

      idempotent! # in the scope of 24 hours

      def perform; end
    end
  end
end
