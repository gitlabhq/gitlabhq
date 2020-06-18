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

  expose :keep_path, if: -> (*) { artifact.expiring? } do |artifact|
    fast_keep_project_job_artifacts_path(artifact.project, artifact.job)
  end

  expose :browse_path do |artifact|
    fast_browse_project_job_artifacts_path(artifact.project, artifact.job)
  end
end
