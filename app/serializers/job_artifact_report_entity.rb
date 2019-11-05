# frozen_string_literal: true

class JobArtifactReportEntity < Grape::Entity
  include RequestAwareEntity

  expose :file_type
  expose :file_format
  expose :size

  expose :download_path do |artifact|
    download_project_job_artifacts_path(artifact.job.project, artifact.job, file_type: artifact.file_type)
  end
end
