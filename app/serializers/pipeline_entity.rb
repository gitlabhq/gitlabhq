class PipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :user, if: proc { created_exposure? }, using: UserEntity

  expose :url do |pipeline|
    namespace_project_pipeline_path(
      pipeline.project.namespace,
      pipeline.project,
      pipeline)
  end

  expose :details, if: proc { updated_exposure? } do
    expose :status
    expose :duration
    expose :finished_at
    expose :stages_with_statuses, as: :stages, using: PipelineStageEntity
    expose :artifacts, using: PipelineArtifactEntity
    expose :manual_actions, using: PipelineActionEntity
  end

  expose :flags, if: proc { created_exposure? } do
    expose :latest?, as: :latest
    expose :triggered?, as: :triggered

    expose :yaml_errors?, as: :yaml_errors do |pipeline|
      pipeline.yaml_errors.present?
    end

    expose :stuck?, as: :stuck do |pipeline|
      pipeline.builds.any?(&:stuck?)
    end
  end

  expose :ref, if: proc { updated_exposure? } do
    expose :name do |pipeline|
      pipeline.ref
    end

    expose :url do |pipeline|
      namespace_project_tree_url(
        pipeline.project.namespace,
        pipeline.project,
        id: pipeline.ref)
    end

    expose :tag?
  end

  expose :commit, if: proc { created_exposure? }, using: CommitEntity

  expose :retry_url, if: proc { updated_exposure? } do |pipeline|
    can?(request.user, :update_pipeline, pipeline.project) &&
      pipeline.retryable? &&
      retry_namespace_project_pipeline_path(pipeline.project.namespace,
                                            pipeline.project, pipeline.id)
  end

  expose :cancel_url, if: proc { updated_exposure? } do |pipeline|
    can?(request.user, :update_pipeline, pipeline.project) &&
      pipeline.cancelable? &&
      cancel_namespace_project_pipeline_path(pipeline.project.namespace,
                                             pipeline.project, pipeline.id)
  end

  def created_exposure?
    !incremental? || created?
  end

  def updated_exposure?
    !incremental? || updated?
  end

  def incremental?
    options[:incremental] && last_updated
  end

  def last_updated
    options.fetch(:last_updated)
  end

  def updated?
    @object.updated_at > last_updated
  end

  def created?
    @object.created_at > last_updated
  end
end
