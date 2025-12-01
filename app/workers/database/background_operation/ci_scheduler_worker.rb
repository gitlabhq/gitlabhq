# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- This is the best place for this module
  module BackgroundOperation
    class CiSchedulerWorker < BaseSchedulerWorker # rubocop:disable Scalability/IdempotentWorker -- parent has it
      def self.worker_class
        Gitlab::Database::BackgroundOperation::Worker
      end

      def self.tracking_database
        Gitlab::Database::CI_DATABASE_NAME.to_sym
      end

      def self.orchestrator_class
        Database::BackgroundOperation::CiOrchestratorWorker
      end
    end
  end
end
