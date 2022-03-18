# frozen_string_literal: true
module Database
  module BatchedBackgroundMigration
    class CiDatabaseWorker # rubocop:disable Scalability/IdempotentWorker
      include SingleDatabaseWorker

      def self.enabled?
        Feature.enabled?(:execute_batched_migrations_on_schedule_ci_database, type: :ops, default_enabled: :yaml)
      end

      def self.tracking_database
        @tracking_database ||= Gitlab::Database::CI_DATABASE_NAME
      end
    end
  end
end
