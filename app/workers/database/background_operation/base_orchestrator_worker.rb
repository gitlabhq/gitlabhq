# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- This is the best place for this module
  module BackgroundOperation
    class BaseOrchestratorWorker # rubocop:disable Scalability/IdempotentWorker -- A LimitedCapacity::Worker
      include ExclusiveLeaseGuard
      include Gitlab::Utils::StrongMemoize
      include ApplicationWorker
      include LimitedCapacity::Worker

      INTERVAL_VARIANCE = 5.seconds.freeze
      LEASE_TIMEOUT_MULTIPLIER = 3

      data_consistency :sticky
      feature_category :database
      prefer_calling_context_feature_category true
      queue_namespace :background_operations

      class << self
        # We have to override this one, as we want
        # arguments passed as is, and not duplicated
        def perform_with_capacity(args)
          worker = new
          worker.remove_failed_jobs

          bulk_perform_async(args)
        end

        def max_running_jobs
          Gitlab::CurrentSettings.background_operations_max_jobs
        end
      end

      def perform_work(worker_class, worker_partition, worker_id, database_name)
        self.database_name = database_name
        self.worker_class = worker_class

        return if shares_db_config?

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          self.worker = find_worker(worker_partition, worker_id)

          break unless worker.present?

          try_obtain_lease do
            run_operation_job if runnable_worker?
          end
        end
      end

      def remaining_work_count(*_args)
        0 # the cron worker is the only source of new jobs
      end

      def max_running_jobs
        self.class.max_running_jobs
      end

      private

      attr_accessor :database_name, :worker_class, :worker

      def base_model
        Gitlab::Database.database_base_models[database_name]
      end
      strong_memoize_attr(:base_model)

      # rubocop:disable CodeReuse/ActiveRecord -- Doesn't have to be a class method on the model
      def find_worker(partition, id)
        worker_class.constantize.executable.where(partition: partition, id: id).first
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def runnable_worker?
        worker.interval_elapsed?(variance: INTERVAL_VARIANCE)
      end

      def lease_key
        [
          database_name,
          worker.class.name.underscore,
          worker.table_name,
          worker.id
        ].join(':')
      end
      strong_memoize_attr(:lease_key)

      def lease_timeout
        worker.interval * LEASE_TIMEOUT_MULTIPLIER
      end

      def run_operation_job
        Gitlab::Database::BackgroundOperation::Runner
          .new(connection: base_model.connection)
          .run_operation_job(worker)
      end

      def shares_db_config?
        Gitlab::Database.db_config_share_with(base_model.connection_db_config).present?
      end
    end
  end
end
