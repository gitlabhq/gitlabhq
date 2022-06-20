# frozen_string_literal: true

module API
  module Helpers
    module ProjectStatsRefreshConflictsHelpers
      def reject_if_build_artifacts_size_refreshing!(project)
        return unless project.refreshing_build_artifacts_size?

        Gitlab::ProjectStatsRefreshConflictsLogger.warn_request_rejected_during_stats_refresh(project.id)

        conflict!('Action temporarily disabled. The project this pipeline belongs to is undergoing stats refresh.')
      end
    end
  end
end
