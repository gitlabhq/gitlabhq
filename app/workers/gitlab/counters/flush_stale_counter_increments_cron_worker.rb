# frozen_string_literal: true

module Gitlab
  module Counters
    class FlushStaleCounterIncrementsCronWorker
      include ApplicationWorker

      # rubocop:disable Scalability/CronWorkerContext -- This is an instance-wide worker and it's not scoped to any context.
      include CronjobQueue

      # rubocop:enable Scalability/CronWorkerContext

      data_consistency :sticky

      feature_category :continuous_integration
      idempotent!

      def perform
        # noop - we'll remove this worker
      end
    end
  end
end
