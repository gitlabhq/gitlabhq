# frozen_string_literal: true

module BackgroundMigration
  class CiDatabaseWorker # rubocop:disable Scalability/IdempotentWorker
    include SingleDatabaseWorker

    def self.tracking_database
      @tracking_database ||= Gitlab::Database::CI_DATABASE_NAME
    end
  end
end
