# frozen_string_literal: true

module Database
  class BatchedBackgroundMigrationWorker # rubocop:disable Scalability/IdempotentWorker
    include BatchedBackgroundMigration::SingleDatabaseWorker

    def self.tracking_database
      @tracking_database ||= Gitlab::Database::MAIN_DATABASE_NAME.to_sym
    end
  end
end
