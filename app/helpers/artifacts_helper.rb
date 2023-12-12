# frozen_string_literal: true

module ArtifactsHelper
  def artifacts_app_data(project)
    {
      project_path: project.full_path,
      project_id: project.id,
      can_destroy_artifacts: can?(current_user, :destroy_artifacts, project).to_s,
      job_artifacts_count_limit: ::Ci::JobArtifacts::BulkDeleteByProjectService::JOB_ARTIFACTS_COUNT_LIMIT
    }
  end
end
