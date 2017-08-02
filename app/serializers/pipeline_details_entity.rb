class PipelineDetailsEntity < PipelineEntity
  expose :details do
    expose :legacy_stages, as: :stages, using: StageEntity
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
  end
end
