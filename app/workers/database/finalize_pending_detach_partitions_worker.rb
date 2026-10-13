# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- home of the other database maintenance cron workers
  class FinalizePendingDetachPartitionsWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- instance-wide database maintenance

    feature_category :database
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- reads the pending state it acts on, so it must not see a lagging replica
    idempotent!

    def perform
      return unless Feature.enabled?(:ci_finalize_pending_detach_partitions_daily, :instance)

      Gitlab::Database::Partitioning.finalize_pending_detach_partitions
    end
  end
end
