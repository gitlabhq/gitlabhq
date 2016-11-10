class PipelineStageEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |stage|
    stage.name
  end

  expose :status do |stage|
    stage.status || 'not found'
  end

  expose :url do |stage|
    namespace_project_pipeline_path(
      stage.pipeline.project.namespace,
      stage.pipeline.project,
      stage.pipeline.id,
      anchor: stage.name)
  end
end
