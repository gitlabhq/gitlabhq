# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DeleteService
      include BaseServiceUtility

      def initialize(build)
        @build = build
      end

      def execute
        if build.project.refreshing_build_artifacts_size?
          Gitlab::ProjectStatsRefreshConflictsLogger.warn_artifact_deletion_during_stats_refresh(
            method: 'Ci::JobArtifacts::DeleteService#execute',
            project_id: build.project_id
          )
          return ServiceResponse.error(
            message: 'Action temporarily disabled. The project this job belongs to is undergoing stats refresh.',
            reason: :project_stats_refresh
          )
        end

        result = Ci::JobArtifacts::DestroyBatchService.new(build.job_artifacts.erasable).execute

        if result.fetch(:status) == :success
          ServiceResponse.success(payload:
          {
            destroyed_artifacts_count: result.fetch(:destroyed_artifacts_count)
          })
        else
          ServiceResponse.error(message: result.fetch(:message))
        end
      end

      private

      attr_reader :build
    end
  end
end
