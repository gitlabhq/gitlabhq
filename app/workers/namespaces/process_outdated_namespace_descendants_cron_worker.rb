# frozen_string_literal: true

module Namespaces
  class ProcessOutdatedNamespaceDescendantsCronWorker
    BATCH_SIZE = 50

    include ApplicationWorker

    data_consistency :always

    # rubocop:disable Scalability/CronWorkerContext -- This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :groups_and_projects
    idempotent!

    def perform
      runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(45.seconds)

      processed_namespaces = 0
      loop do
        namespace_ids = Namespaces::Descendants.load_outdated_batch(BATCH_SIZE)

        break if namespace_ids.empty?

        namespace_ids.each do |namespace_id|
          Namespaces::UpdateDenormalizedDescendantsService
            .new(namespace_id: namespace_id)
            .execute

          processed_namespaces += 1
          break if runtime_limiter.over_time?
        end

        break if runtime_limiter.over_time?
      end

      log_extra_metadata_on_done(:result, { processed_namespaces: processed_namespaces })
    end
  end
end
