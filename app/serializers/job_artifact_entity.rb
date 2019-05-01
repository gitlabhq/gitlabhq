# frozen_string_literal: true

class JobArtifactEntity < Grape::Entity
  include RequestAwareEntity

  expose :file_type
  expose :file_format
  expose :size

  expose :download_path do |artifact|
    download_project_job_artifacts_path(job.project, job, file_type: artifact.file_format)
  end

  alias_method :job, :object
end
