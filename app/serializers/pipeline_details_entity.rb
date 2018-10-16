# frozen_string_literal: true

class PipelineDetailsEntity < PipelineEntity
  expose :details do
    expose :ordered_stages, as: :stages, using: StageEntity
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
    expose :detailed_deployments_status, using: DetailedStatusEntity
  end

  private

  def detailed_deployments_status
    pipeline.detailed_deployments_status(request.current_user)
  end
end
