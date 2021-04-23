# frozen_string_literal: true

module Ci
  class DownloadableArtifactEntity < Grape::Entity
    include RequestAwareEntity

    expose :artifacts do |pipeline, options|
      artifacts = pipeline.downloadable_artifacts

      if Feature.enabled?(:non_public_artifacts)
        artifacts = artifacts.select { |artifact| can?(request.current_user, :read_job_artifacts, artifact.job) }
      end

      BuildArtifactEntity.represent(artifacts, options.merge(project: pipeline.project))
    end
  end
end
