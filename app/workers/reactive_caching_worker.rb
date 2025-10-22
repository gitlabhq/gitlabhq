# frozen_string_literal: true

class ReactiveCachingWorker # rubocop:disable Scalability/IdempotentWorker
  include ReactiveCacheableWorker

  urgency :low
  worker_resource_boundary :cpu
  max_concurrency_limit_percentage 0.5
end
