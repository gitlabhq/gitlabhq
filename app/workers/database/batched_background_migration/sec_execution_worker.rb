# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Doesn't make sense to put this elsewhere
  module BatchedBackgroundMigration
    class SecExecutionWorker # rubocop:disable Scalability/IdempotentWorker -- Not guaranteed to be idempotent
      include ExecutionWorker
    end
  end
end
