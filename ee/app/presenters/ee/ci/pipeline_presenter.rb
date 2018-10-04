module EE
  module Ci
    module PipelinePresenter
      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 'Pipeline activity limit exceeded!',
        size_limit_exceeded: 'Pipeline size limit exceeded!'
      }.freeze

      def downloadable_url_for_report_type(file_type)
        if (job_artifact = artifact_for_file_type(file_type)) &&
            can?(current_user, :read_build, job_artifact.build)
          return download_project_build_artifacts_url(
            job_artifact.project,
            job_artifact.build,
            file_type: file_type)
        end

        if (build_artifact = legacy_report_artifact_for_file_type(file_type)) &&
            can?(current_user, :read_build, build_artifact.build)
          return raw_project_build_artifacts_url(
            build_artifact.build.project,
            build_artifact.build,
            path: build_artifact.path)
        end
      end
    end
  end
end
