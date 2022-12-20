# frozen_string_literal: true

module Database
  class BatchedBackgroundMigrationWorker # rubocop:disable Scalability/IdempotentWorker
    include BatchedBackgroundMigration::SingleDatabaseWorker

    def self.tracking_database
      @tracking_database ||= Gitlab::Database::MAIN_DATABASE_NAME.to_sym
    end

    def execution_worker_class
      @execution_worker_class ||= Database::BatchedBackgroundMigration::MainExecutionWorker
    end
  end
end
