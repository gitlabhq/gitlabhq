# frozen_string_literal: true

class PipelineDetailsEntity < PipelineEntity
  expose :details do
    expose :ordered_stages, as: :stages, using: StageEntity
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
    expose :deployments_statuses, using: DetailedStatusEntity
  end

  private

  def deployments_statuses
    pipeline.detailed_deployments_status(request.current_user)
  end
end
