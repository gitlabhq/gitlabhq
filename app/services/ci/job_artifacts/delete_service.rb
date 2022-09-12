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
        end

        # fix_expire_at is false because in this case we want to explicitly delete the job artifacts
        # this flag is a workaround that will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/355833
        Ci::JobArtifacts::DestroyBatchService.new(build.job_artifacts.erasable, fix_expire_at: false).execute

        ServiceResponse.success
      end

      private

      attr_reader :build
    end
  end
end
