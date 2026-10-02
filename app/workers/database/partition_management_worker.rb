# frozen_string_literal: true

module Database
  class PartitionManagementWorker
    include ApplicationWorker

    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :always

    feature_category :database
    idempotent!

    def perform
      Gitlab::Database::Partitioning.sync_partitions(analyze_tables_with_default_interval: true)
    ensure
      Gitlab::Database::Partitioning.report_metrics
    end
  end
end
