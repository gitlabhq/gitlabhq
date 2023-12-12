# frozen_string_literal: true

module Ci
  module JobArtifacts
    class BulkDeleteByProjectService
      include BaseServiceUtility

      JOB_ARTIFACTS_COUNT_LIMIT = 100

      def initialize(job_artifact_ids:, project:, current_user:)
        @job_artifact_ids = job_artifact_ids
        @project = project
        @current_user = current_user
      end

      def execute
        if exceeds_limits?
          return ServiceResponse.error(
            message: "Can only delete up to #{JOB_ARTIFACTS_COUNT_LIMIT} job artifacts per call"
          )
        end

        find_result = find_artifacts

        return ServiceResponse.error(message: find_result[:error_message]) if find_result[:error_message]

        @job_artifact_scope = find_result[:scope]

        unless all_job_artifacts_belong_to_project?
          return ServiceResponse.error(message: 'Not all artifacts belong to requested project')
        end

        result = Ci::JobArtifacts::DestroyBatchService.new(job_artifact_scope).execute

        destroyed_artifacts_count = result.fetch(:destroyed_artifacts_count)
        destroyed_ids = result.fetch(:destroyed_ids)

        ServiceResponse.success(
          payload: {
            destroyed_count: destroyed_artifacts_count,
            destroyed_ids: destroyed_ids,
            errors: []
          })
      end

      private

      def find_artifacts
        job_artifacts = ::Ci::JobArtifact.id_in(job_artifact_ids)

        error_message = nil
        if job_artifacts.count != job_artifact_ids.count
          not_found_artifacts = job_artifact_ids - job_artifacts.map(&:id)
          error_message = "Artifacts (#{not_found_artifacts.join(',')}) not found"
        end

        { scope: job_artifacts, error_message: error_message }
      end

      def exceeds_limits?
        job_artifact_ids.count > JOB_ARTIFACTS_COUNT_LIMIT
      end

      def all_job_artifacts_belong_to_project?
        # rubocop:disable CodeReuse/ActiveRecord
        job_artifact_scope.pluck(:project_id).all?(project.id)
        # rubocop:enable CodeReuse/ActiveRecord
      end

      attr_reader :job_artifact_ids, :job_artifact_scope, :current_user, :project
    end
  end
end
