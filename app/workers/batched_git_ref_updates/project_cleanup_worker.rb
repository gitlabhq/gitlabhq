# frozen_string_literal: true

module BatchedGitRefUpdates
  class ProjectCleanupWorker
    include ApplicationWorker

    idempotent!
    data_consistency :delayed

    feature_category :gitaly

    def perform(project_id)
      stats = ProjectCleanupService.new(project_id).execute

      log_extra_metadata_on_done(:stats, stats)
    end
  end
end
