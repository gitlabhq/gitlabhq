# frozen_string_literal: true

class PipelineDetailsEntity < Ci::PipelineEntity
  expose :project, using: ProjectEntity

  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
    expose :code_quality_build_path, if: -> (_, options) { options[:code_quality_walkthrough] } do |pipeline|
      next unless code_quality_build = pipeline.builds.finished.find_by_name('code_quality')

      project_job_path(pipeline.project, code_quality_build, code_quality_walkthrough: true)
    end
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
