# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Database Framework
  module BackgroundOperation
    class BaseSchedulerWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- called from cron
      include Database::BackgroundWorkSchedulable

      idempotent!
      data_consistency :sticky
      feature_category :database

      MAX_RUNNING_OPERATIONS = 2

      def self.schedule_feature_flag_name
        # TODO; Add a FF in https://gitlab.com/gitlab-org/gitlab/-/issues/577666
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
        # Orchestrator worker will be created in https://gitlab.com/gitlab-org/gitlab/-/issues/578058
        # Which will get `MAX_RUNNING_OPERATIONS` from ApplicationSettings, similar to BBM.

        self.class.worker_class.schedulable_workers(MAX_RUNNING_OPERATIONS).to_a
      end

      def queue_workers_for_execution(workers)
        # Orchestrator worker will be created in https://gitlab.com/gitlab-org/gitlab/-/issues/578058
        # Which will uncomment below lines

        # return unless workers.present?

        # jobs_arguments = workers.map { |worker| [tracking_database.to_s, worker.id] }

        # orchestrator_worker_class.perform_with_capacity(jobs_arguments)
      end
    end
  end
end
