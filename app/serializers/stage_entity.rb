class StageEntity < Grape::Entity
  include RequestAwareEntity

  expose :name

  expose :title do |stage|
    "#{stage.name}: #{detailed_status.label}"
  end

  expose :groups,
    if: -> (_, opts) { opts[:grouped] },
    with: JobGroupEntity

  expose :detailed_status, as: :status, with: StatusEntity

  expose :path do |stage|
    project_pipeline_path(
      stage.pipeline.project,
      stage.pipeline,
      anchor: stage.name)
  end

  expose :dropdown_path do |stage|
    stage_project_pipeline_path(
      stage.pipeline.project,
      stage.pipeline,
      stage: stage.name,
      format: :json)
  end

  private

  alias_method :stage, :object

  def detailed_status
    stage.detailed_status(request.current_user)
  end
end
