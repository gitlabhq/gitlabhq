# frozen_string_literal: true

class PipelineDetailsEntity < Ci::PipelineEntity
  expose :project, using: ProjectEntity

  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :manual_actions, if: ->(pipeline, _) { Feature.disabled?(:lazy_load_manual_actions, pipeline.project) },
      using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
    expose :has_manual_actions do |pipeline|
      pipeline.manual_actions.any?
    end
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
