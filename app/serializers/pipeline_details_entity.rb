class PipelineDetailsEntity < PipelineEntity
  expose :yaml_errors, if: -> (pipeline, _) { pipeline.has_yaml_errors? }
  
  expose :details do
    expose :detailed_status, as: :status, with: StatusEntity
    expose :duration
    expose :finished_at
    expose :stages, using: StageEntity
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
  end

  expose :flags do
    expose :latest?, as: :latest
    expose :triggered?, as: :triggered
    expose :stuck?, as: :stuck
    expose :has_yaml_errors?, as: :yaml_errors
    expose :can_retry?, as: :retryable
    expose :can_cancel?, as: :cancelable
  end
end
