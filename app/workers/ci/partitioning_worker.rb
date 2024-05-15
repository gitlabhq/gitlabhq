# frozen_string_literal: true

module Ci
  class PartitioningWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- No metadata necessary

    feature_category :ci_scaling
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- cron job
    deduplicate :until_executed
    idempotent!

    def perform
      Ci::Partitions::SetupDefaultService.new.execute
    end
  end
end
