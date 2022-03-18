# frozen_string_literal: true
module Database
  module BatchedBackgroundMigration
    class CiDatabaseWorker # rubocop:disable Scalability/IdempotentWorker
      include SingleDatabaseWorker

      def self.tracking_database
        @tracking_database ||= Gitlab::Database::CI_DATABASE_NAME
      end
    end
  end
end
