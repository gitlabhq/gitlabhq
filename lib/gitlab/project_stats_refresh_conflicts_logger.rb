# frozen_string_literal: true

module Gitlab
  class ProjectStatsRefreshConflictsLogger # rubocop:disable Gitlab/NamespacedClass
    def self.warn_artifact_deletion_during_stats_refresh(project_id:, method:)
      payload = Gitlab::ApplicationContext.current.merge(
        message: 'Deleted artifacts undergoing refresh',
        method: method,
        project_id: project_id
      )

      Gitlab::AppLogger.warn(payload)
    end

    def self.warn_request_rejected_during_stats_refresh(project_id)
      payload = Gitlab::ApplicationContext.current.merge(
        message: 'Rejected request due to project undergoing stats refresh',
        project_id: project_id
      )

      Gitlab::AppLogger.warn(payload)
    end

    def self.warn_skipped_artifact_deletion_during_stats_refresh(project_ids:, method:)
      payload = Gitlab::ApplicationContext.current.merge(
        message: 'Skipped deleting artifacts undergoing refresh',
        method: method,
        project_ids: project_ids
      )

      Gitlab::AppLogger.warn(payload)
    end
  end
end
