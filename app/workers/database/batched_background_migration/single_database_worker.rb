# frozen_string_literal: true

module Database
  module BatchedBackgroundMigration
    module SingleDatabaseWorker
      extend ActiveSupport::Concern

      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- called from cron
      include Database::BackgroundWorkSchedulable

      class_methods do
        def schedule_feature_flag_name
          :execute_batched_migrations_on_schedule
        end
      end

      included do
        data_consistency :always
        feature_category :database
        idempotent!
      end

      def perform
        return unless validate!

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          break unless self.class.enabled?

          migrations = Gitlab::Database::BackgroundMigration::BatchedMigration
            .active_migrations_distinct_on_table(connection: base_model.connection, limit: max_running_migrations).to_a

          queue_migrations_for_execution(migrations) if migrations.any?
        end
      end

      private

      def queue_migrations_for_execution(migrations)
        jobs_arguments = migrations.map { |migration| [tracking_database.to_s, migration.id] }

        execution_worker_class.perform_with_capacity(jobs_arguments)
      end
    end
  end
end
