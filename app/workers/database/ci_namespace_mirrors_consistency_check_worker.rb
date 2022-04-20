# frozen_string_literal: true

module Database
  class CiNamespaceMirrorsConsistencyCheckWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :sharding
    data_consistency :sticky
    idempotent!

    version 1

    def perform
      return if Feature.disabled?(:ci_namespace_mirrors_consistency_check, default_enabled: :yaml)

      results = ConsistencyCheckService.new(
        source_model: Namespace,
        target_model: Ci::NamespaceMirror,
        source_columns: %w[id traversal_ids],
        target_columns: %w[namespace_id traversal_ids]
      ).execute

      log_extra_metadata_on_done(:results, results)
    end
  end
end
