# frozen_string_literal: true

class BuildArtifactEntity < Grape::Entity
  include RequestAwareEntity
  include GitlabRoutingHelper

  alias_method :artifact, :object

  expose :name do |artifact|
    "#{artifact.job.name}:#{artifact.file_type}"
  end

  expose :file_type

  expose :expire_at
  expose :expired?, as: :expired

  expose :path do |artifact|
    fast_download_project_job_artifacts_path(
      project,
      artifact.job,
      file_type: artifact.file_type
    )
  end

  private

  def project
    options[:project] || artifact.project
  end
end
