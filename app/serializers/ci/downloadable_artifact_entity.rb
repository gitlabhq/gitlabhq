# frozen_string_literal: true

module Ci
  class DownloadableArtifactEntity < Grape::Entity
    include RequestAwareEntity

    expose :artifacts do |pipeline, options|
      artifacts = pipeline.downloadable_artifacts
      project = pipeline.project

      if Feature.enabled?(:non_public_artifacts, project)
        artifacts = artifacts.select { |artifact| can?(request.current_user, :read_job_artifacts, artifact) }
      end

      BuildArtifactEntity.represent(artifacts, options.merge(project: project))
    end
  end
end
