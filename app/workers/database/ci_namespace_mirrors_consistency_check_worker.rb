# frozen_string_literal: true

module Database
  class CiNamespaceMirrorsConsistencyCheckWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :cell
    data_consistency :sticky
    idempotent!

    version 1

    def perform
      results = ConsistencyCheckService.new(
        source_model: Namespace,
        target_model: Ci::NamespaceMirror,
        source_columns: %w[id traversal_ids],
        target_columns: %w[namespace_id traversal_ids]
      ).execute

      if results[:mismatches_details].any?
        ConsistencyFixService.new(
          source_model: Namespace,
          target_model: Ci::NamespaceMirror,
          sync_event_class: Namespaces::SyncEvent,
          source_sort_key: :id,
          target_sort_key: :namespace_id
        ).execute(ids: results[:mismatches_details].map { |h| h[:id] })
      end

      log_extra_metadata_on_done(:results, results)
    end
  end
end
