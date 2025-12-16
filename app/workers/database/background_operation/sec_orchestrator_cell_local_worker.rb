# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- This is the best place for this module
  module BackgroundOperation
    class SecOrchestratorCellLocalWorker < BaseOrchestratorWorker; end # rubocop:disable Scalability/IdempotentWorker -- A LimitedCapacity::Worker
  end
end
