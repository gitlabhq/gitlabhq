# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- This is the best place for this module
  module BackgroundOperation
    class BaseSchedulerWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- called from cron
      include Database::BackgroundWorkSchedulable

      idempotent!
      data_consistency :sticky
      feature_category :database

      def self.scheduler_feature_flag_enabled?
        Feature.enabled?(:schedule_background_operations, type: :ops) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Global FF
      end

      def perform
        return unless validate!

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          break unless self.class.enabled?

          queue_workers_for_execution(queueable_workers)
        end
      end

      private

      def queueable_workers
        self.class.worker_class.schedulable_workers(self.class.orchestrator_class.max_running_jobs).to_a
      end

      def queue_workers_for_execution(workers)
        return unless workers.present?

        jobs_arguments = workers.map do |worker|
          [worker.class.name, worker.partition, worker.id, tracking_database.to_s]
        end

        self.class.orchestrator_class.perform_with_capacity(jobs_arguments)
      end
    end
  end
end
