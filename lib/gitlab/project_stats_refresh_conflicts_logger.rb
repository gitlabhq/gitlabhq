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
  end
end
