# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- It's a general purpose module
# rubocop:disable Scalability/IdempotentWorker -- Also disabled for parent worker
# rubocop:disable Sidekiq/EnforceDatabaseHealthSignalDeferral -- The worker can be called by several classes
module ReactiveCaching
  class LowUrgencyWorker < ReactiveCachingWorker
    urgency :low
  end
end
# rubocop:enable Gitlab/BoundedContexts
# rubocop:enable Scalability/IdempotentWorker
# rubocop:enable Sidekiq/EnforceDatabaseHealthSignalDeferral
