# frozen_string_literal: true

class PipelineDetailsEntity < Ci::PipelineEntity
  expose :project, using: ProjectEntity

  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :artifacts do |pipeline, options|
      rel = pipeline.downloadable_artifacts

      if Feature.enabled?(:non_public_artifacts, type: :development)
        rel = rel.select { |artifact| can?(request.current_user, :read_job_artifacts, artifact.job) }
      end

      BuildArtifactEntity.represent(rel, options)
    end
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
