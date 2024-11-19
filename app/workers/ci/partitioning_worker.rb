# frozen_string_literal: true

module Ci
  class PartitioningWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- No metadata necessary

    feature_category :ci_scaling
    data_consistency :always
    deduplicate :until_executed
    idempotent!

    def perform
      Ci::Partitions::SetupDefaultService.new.execute

      ci_partition_current = Ci::Partition.current
      return unless ci_partition_current

      Ci::Partitions::CreateService.new(ci_partition_current).execute
      Ci::Partitions::SyncService.new(ci_partition_current).execute
    end
  end
end
