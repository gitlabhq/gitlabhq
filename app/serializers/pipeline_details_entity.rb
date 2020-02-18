# frozen_string_literal: true

class PipelineDetailsEntity < PipelineEntity
  expose :project, using: ProjectEntity

  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :artifacts do |pipeline, options|
      rel = pipeline.artifacts
      rel = rel.eager_load_job_artifacts_archive if options.fetch(:preload_job_artifacts_archive, true)

      BuildArtifactEntity.represent(rel, options)
    end
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
