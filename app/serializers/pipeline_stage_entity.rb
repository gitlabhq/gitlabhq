class PipelineStageEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :detailed_status, as: :status, using: StatusEntity

  expose :path do |stage|
    namespace_project_pipeline_path(
      stage.pipeline.project.namespace,
      stage.pipeline.project,
      stage.pipeline.id,
      anchor: stage.name)
  end
end
