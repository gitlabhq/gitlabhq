# frozen_string_literal: true

module Database
  module BatchedBackgroundMigration
    class MainExecutionWorker # rubocop:disable Scalability/IdempotentWorker
      include ExecutionWorker
    end
  end
end
