# frozen_string_literal: true

module Environments
  class AutoDeleteCronWorker
    include ApplicationWorker
    include ::Gitlab::LoopHelpers
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :always
    feature_category :continuous_delivery
    deduplicate :until_executed, including_scheduled: true
    idempotent!

    LOOP_TIMEOUT = 45.minutes
    LOOP_LIMIT = 1000
    BATCH_SIZE = 100

    def perform
      loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
        destroy_in_batch
      end
    end

    private

    def destroy_in_batch
      environments = Environment.auto_deletable(BATCH_SIZE)

      return false if environments.empty?

      environments.each(&:destroy)
    end
  end
end
