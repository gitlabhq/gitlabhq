# frozen_string_literal: true

class PipelineDetailsEntity < PipelineEntity
  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
