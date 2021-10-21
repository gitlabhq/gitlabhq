# frozen_string_literal: true

module Database
  class DropDetachedPartitionsWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :database
    data_consistency :always
    idempotent!

    def perform
      Gitlab::Database::Partitioning.drop_detached_partitions
    ensure
      Gitlab::Database::Partitioning.report_metrics
    end
  end
end
