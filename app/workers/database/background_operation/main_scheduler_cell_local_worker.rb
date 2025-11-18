# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Database Framework
  module BackgroundOperation
    class MainSchedulerCellLocalWorker < BaseSchedulerWorker # rubocop:disable Scalability/IdempotentWorker -- parent has it
      def self.worker_class
        Gitlab::Database::BackgroundOperation::WorkerCellLocal
      end

      def self.tracking_database
        Gitlab::Database::MAIN_DATABASE_NAME.to_sym
      end
    end
  end
end
