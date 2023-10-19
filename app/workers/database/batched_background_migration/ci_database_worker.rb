# frozen_string_literal: true

module Database
  module BatchedBackgroundMigration
    class CiDatabaseWorker # rubocop:disable Scalability/IdempotentWorker
      include SingleDatabaseWorker

      def self.tracking_database
        @tracking_database ||= Gitlab::Database::CI_DATABASE_NAME.to_sym
      end

      def execution_worker_class
        @execution_worker_class ||= Database::BatchedBackgroundMigration::CiExecutionWorker
      end
    end
  end
end
