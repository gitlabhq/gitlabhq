# frozen_string_literal: true

class PipelineDetailsEntity < Ci::PipelineEntity
  expose :project, using: ProjectEntity

  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :manual_actions, unless: proc { options[:disable_manual_and_scheduled_actions] }, using: BuildActionEntity
    expose :scheduled_actions, unless: proc { options[:disable_manual_and_scheduled_actions] }, using: BuildActionEntity
    expose :has_manual_actions do |pipeline|
      pipeline.manual_actions.any?
    end
    expose :has_scheduled_actions do |pipeline|
      pipeline.scheduled_actions.any?
    end
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
