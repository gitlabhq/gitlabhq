# frozen_string_literal: true

module Database
  class CiProjectMirrorsConsistencyCheckWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :cell
    data_consistency :sticky
    idempotent!

    version 1

    def perform
      results = ConsistencyCheckService.new(
        source_model: Project,
        target_model: Ci::ProjectMirror,
        source_columns: %w[id namespace_id],
        target_columns: %w[project_id namespace_id]
      ).execute

      if results[:mismatches_details].any?
        ConsistencyFixService.new(
          source_model: Project,
          target_model: Ci::ProjectMirror,
          sync_event_class: Projects::SyncEvent,
          source_sort_key: :id,
          target_sort_key: :project_id
        ).execute(ids: results[:mismatches_details].map { |h| h[:id] })
      end

      log_extra_metadata_on_done(:results, results)
    end
  end
end
