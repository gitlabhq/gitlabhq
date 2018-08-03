# frozen_string_literal: true

class PipelineDetailsEntity < PipelineEntity
  expose :details do
    expose :ordered_stages, as: :stages, using: StageEntity
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
  end
end
