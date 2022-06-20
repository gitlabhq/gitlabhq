# frozen_string_literal: true

module ProjectStatsRefreshConflictsGuard
  extend ActiveSupport::Concern

  def reject_if_build_artifacts_size_refreshing!
    return unless project.refreshing_build_artifacts_size?

    Gitlab::ProjectStatsRefreshConflictsLogger.warn_request_rejected_during_stats_refresh(project.id)

    render_409('Action temporarily disabled. The project this pipeline belongs to is undergoing stats refresh.')
  end
end
