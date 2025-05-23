# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Doesn't make sense to put this elsewhere
  module BatchedBackgroundMigration
    class SecDatabaseWorker # rubocop:disable Scalability/IdempotentWorker  -- SingleDatabaseWorker is idempotent!
      include SingleDatabaseWorker

      def self.tracking_database
        @tracking_database ||= Gitlab::Database::SEC_DATABASE_NAME.to_sym
      end

      def execution_worker_class
        @execution_worker_class ||= Database::BatchedBackgroundMigration::SecExecutionWorker
      end
    end
  end
end
