class PipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :user, using: UserEntity

  expose :url do |pipeline|
    namespace_project_pipeline_path(
      pipeline.project.namespace,
      pipeline.project,
      pipeline)
  end

  expose :details do
    expose :detailed_status, as: :status, using: StatusEntity
    expose :duration
    expose :finished_at
    expose :stages, using: PipelineStageEntity
    expose :artifacts, using: PipelineArtifactEntity
    expose :manual_actions, using: PipelineActionEntity
  end

  expose :flags do
    expose :latest?, as: :latest
    expose :triggered?, as: :triggered

    expose :yaml_errors?, as: :yaml_errors do |pipeline|
      pipeline.yaml_errors.present?
    end

    expose :stuck?, as: :stuck do |pipeline|
      pipeline.builds.any?(&:stuck?)
    end
  end

  expose :ref do
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

  expose :commit, using: CommitEntity

  expose :retry_url do |pipeline|
    can?(request.user, :update_pipeline, pipeline.project) &&
      pipeline.retryable? &&
      retry_namespace_project_pipeline_path(pipeline.project.namespace,
                                            pipeline.project, pipeline.id)
  end

  expose :cancel_url do |pipeline|
    can?(request.user, :update_pipeline, pipeline.project) &&
      pipeline.cancelable? &&
      cancel_namespace_project_pipeline_path(pipeline.project.namespace,
                                             pipeline.project, pipeline.id)
  end

  expose :created_at, :updated_at
end
