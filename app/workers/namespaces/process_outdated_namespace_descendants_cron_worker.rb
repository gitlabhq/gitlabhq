# frozen_string_literal: true

module Namespaces
  class ProcessOutdatedNamespaceDescendantsCronWorker
    BATCH_SIZE = 50

    include ApplicationWorker
    include LoopWithRuntimeLimit

    MAX_RUNTIME = 45.seconds

    data_consistency :always

    # rubocop:disable Scalability/CronWorkerContext -- This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :groups_and_projects
    idempotent!

    def perform
      results = {}

      loop_with_runtime_limit(MAX_RUNTIME) do |runtime_limiter|
        namespace_ids = Namespaces::Descendants.load_outdated_batch(BATCH_SIZE)
        break if namespace_ids.empty?

        namespace_ids.each do |namespace_id|
          result = Namespaces::UpdateDenormalizedDescendantsService
            .new(namespace_id: namespace_id)
            .execute

          results[result] ||= 0
          results[result] += 1

          break if runtime_limiter.over_time?
        end

        # Stop the processing if we had unprocessed namespace. The worker will try it again later.
        break if results.keys != [:processed]
      end

      log_extra_metadata_on_done(:result, results)
    end
  end
end
