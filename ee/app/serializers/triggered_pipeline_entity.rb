class TriggeredPipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :user, using: UserEntity
  expose :active?, as: :active
  expose :coverage
  expose :source

  expose :path do |pipeline|
    project_pipeline_path(pipeline.project, pipeline)
  end

  expose :details do
    expose :detailed_status, as: :status, with: DetailedStatusEntity
  end

  expose :project, using: ProjectEntity

  private

  alias_method :pipeline, :object

  def detailed_status
    pipeline.detailed_status(request.current_user)
  end
end
