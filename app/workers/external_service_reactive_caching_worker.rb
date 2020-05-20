# frozen_string_literal: true

class ExternalServiceReactiveCachingWorker # rubocop:disable Scalability/IdempotentWorker
  include ReactiveCacheableWorker

  worker_has_external_dependencies!
end
