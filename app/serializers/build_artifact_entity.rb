# frozen_string_literal: true

class BuildArtifactEntity < Grape::Entity
  include RequestAwareEntity
  include GitlabRoutingHelper

  alias_method :artifact, :object

  expose :name do |artifact|
    "#{artifact.job.name}:#{artifact.file_type}"
  end

  expose :expire_at
  expose :expired?, as: :expired

  expose :path do |artifact|
    fast_download_project_job_artifacts_path(
      artifact.project,
      artifact.job,
      file_type: artifact.file_type
    )
  end

  expose :keep_path, if: -> (*) { artifact.expiring? && show_duplicated_paths?(artifact.project) } do |artifact|
    fast_keep_project_job_artifacts_path(artifact.project, artifact.job)
  end

  expose :browse_path, if: -> (*) { show_duplicated_paths?(artifact.project) } do |artifact|
    fast_browse_project_job_artifacts_path(artifact.project, artifact.job)
  end

  private

  def show_duplicated_paths?(project)
    !Gitlab::Ci::Features.remove_duplicate_artifact_exposure_paths?(project)
  end
end
