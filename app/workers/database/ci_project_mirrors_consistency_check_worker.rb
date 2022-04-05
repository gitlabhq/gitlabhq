# frozen_string_literal: true

module Database
  class CiProjectMirrorsConsistencyCheckWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :sharding
    data_consistency :sticky
    idempotent!

    version 1

    def perform
      return if Feature.disabled?(:ci_project_mirrors_consistency_check, default_enabled: :yaml)

      results = ConsistencyCheckService.new(
        source_model: Project,
        target_model: Ci::ProjectMirror,
        source_columns: %w[id namespace_id],
        target_columns: %w[project_id namespace_id]
      ).execute

      log_extra_metadata_on_done(:results, results)
    end
  end
end
