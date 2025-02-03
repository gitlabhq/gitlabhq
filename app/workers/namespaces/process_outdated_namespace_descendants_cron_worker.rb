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
      skipped_namespaces = 0
      processed_namespaces = 0

      loop_with_runtime_limit(MAX_RUNTIME) do |runtime_limiter|
        namespace_ids = Namespaces::Descendants.load_outdated_batch(BATCH_SIZE)
        break if namespace_ids.empty?

        namespace_ids.each do |namespace_id|
          result = Namespaces::UpdateDenormalizedDescendantsService
            .new(namespace_id: namespace_id)
            .execute

          if result == :processed
            processed_namespaces += 1
          else
            skipped_namespaces += 1
          end

          break if runtime_limiter.over_time?
        end

        # Stop the processing if we had to skip a namespace. The worker will try it again later.
        break if skipped_namespaces > 0
      end

      log_extra_metadata_on_done(:result,
        { processed_namespaces: processed_namespaces, skipped_namespaces: skipped_namespaces })
    end
  end
end
