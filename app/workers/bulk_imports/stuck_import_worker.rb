# frozen_string_literal: true

# rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- Worker is no-op, pending removal
module BulkImports
  # TODO: Remove once no jobs are being enqueued with this worker class
  # (after 16.9 is released + 1 week)
  class StuckImportWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- This worker does not schedule other workers that require context.

    idempotent!

    feature_category :importers

    def perform; end
  end
end
# rubocop:enable SidekiqLoadBalancing/WorkerDataConsistency
