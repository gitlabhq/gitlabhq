class PipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :user, using: UserEntity
  expose :active?, as: :active
  expose :coverage

  expose :created_at, :updated_at

  expose :path do |pipeline|
    namespace_project_pipeline_path(
      pipeline.project.namespace,
      pipeline.project,
      pipeline)
  end

  expose :ref do
    expose :name do |pipeline|
      pipeline.ref
    end

    expose :path do |pipeline|
      if pipeline.ref
        project_ref_path(pipeline.project, pipeline.ref)
      end
    end

    expose :tag?, as: :tag
    expose :branch?, as: :branch
  end

  expose :commit, using: CommitEntity

  expose :retry_path, if: -> (*) { can_retry? }  do |pipeline|
    retry_namespace_project_pipeline_path(pipeline.project.namespace,
                                          pipeline.project,
                                          pipeline.id)
  end

  expose :cancel_path, if: -> (*) { can_cancel? } do |pipeline|
    cancel_namespace_project_pipeline_path(pipeline.project.namespace,
                                           pipeline.project,
                                           pipeline.id)
  end

  private

  alias_method :pipeline, :object

  def can_retry?
    can?(request.current_user, :update_pipeline, pipeline) &&
      pipeline.retryable?
  end

  def can_cancel?
    can?(request.current_user, :update_pipeline, pipeline) &&
      pipeline.cancelable?
  end

  def detailed_status
    pipeline.detailed_status(request.current_user)
  end
end
