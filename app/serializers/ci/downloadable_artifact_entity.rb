# frozen_string_literal: true

module Ci
  class DownloadableArtifactEntity < Grape::Entity
    include RequestAwareEntity

    expose :artifacts do |pipeline, options|
      downloadable_artifacts = pipeline.downloadable_artifacts
      project = pipeline.project

      artifacts = downloadable_artifacts.select { |artifact| can?(request.current_user, :read_job_artifacts, artifact) }

      BuildArtifactEntity.represent(artifacts, options.merge(project: project))
    end
  end
end
