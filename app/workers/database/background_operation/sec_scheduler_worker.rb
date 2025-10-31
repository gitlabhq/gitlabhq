# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Database Framework
  module BackgroundOperation
    class SecSchedulerWorker < BaseSchedulerWorker # rubocop:disable Scalability/IdempotentWorker -- parent has it
      def self.worker_class
        Gitlab::Database::BackgroundOperation::Worker
      end

      def self.tracking_database
        Gitlab::Database::SEC_DATABASE_NAME.to_sym
      end
    end
  end
end
