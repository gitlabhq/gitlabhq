class StageEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :status do |stage, options|
    StatusEntity.represent(
      stage.detailed_status(request.user),
      options)
  end

  expose :path do |stage|
    namespace_project_pipeline_path(
      stage.pipeline.project.namespace,
      stage.pipeline.project,
      stage.pipeline.id,
      anchor: stage.name)
  end
end
