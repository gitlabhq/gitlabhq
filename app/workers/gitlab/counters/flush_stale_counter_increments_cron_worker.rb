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
        return unless ::Gitlab.com_except_jh? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- we need to check on which instance this happens

        FlushStaleCounterIncrementsWorker.perform_with_capacity
      end
    end
  end
end
