class PipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :user, if: -> (pipeline, opts) { created?(pipeline, opts) }, using: UserEntity
  expose :url do |pipeline|
    namespace_project_pipeline_path(
      pipeline.project.namespace,
      pipeline.project,
      pipeline)
  end

  expose :details, if: -> (pipeline, opts) { updated?(pipeline, opts) } do
    expose :status
    expose :duration
    expose :finished_at
    expose :stages_with_statuses, as: :stages, using: PipelineStageEntity
    expose :artifacts, using: PipelineArtifactEntity
    expose :manual_actions, using: PipelineActionEntity
  end

  expose :flags, if: -> (pipeline, opts) { created?(pipeline, opts) } do
    expose :latest?, as: :latest
    expose :triggered?, as: :triggered
    expose :yaml_errors?, as: :yaml_errors do |pipeline|
      pipeline.yaml_errors.present?
    end
    expose :stuck?, as: :stuck do |pipeline|
      pipeline.builds.any?(&:stuck?)
    end
  end

  expose :ref, if: -> (pipeline, opts) { created?(pipeline, opts) } do
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

  expose :commit, if: -> (pipeline, opts) { created?(pipeline, opts) }, using: CommitEntity

  expose :retry_url, if: -> (pipeline, opts) { updated?(pipeline, opts) } do |pipeline|
    can?(current_user, :update_pipeline, pipeline.project) &&
      pipeline.retryable? &&
      retry_namespace_project_pipeline_path(pipeline.project.namespace, pipeline.project, pipeline.id)
  end

  expose :cancel_url, if: -> (pipeline, opts) { updated?(pipeline, opts) } do |pipeline|
    can?(current_user, :update_pipeline, pipeline.project) &&
      pipeline.cancelable? &&
      cancel_namespace_project_pipeline_path(pipeline.project.namespace, pipeline.project, pipeline.id)
  end

  private

  def last_updated(opts)
    opts.fetch(:last_updated)
  end

  def created?(pipeline, opts)
    !last_updated(opts) || pipeline.created_at > last_updated(opts)
  end

  def updated?(pipeline, opts)
    !last_updated(opts) || pipeline.updated_at > last_updated(opts)
  end
end
