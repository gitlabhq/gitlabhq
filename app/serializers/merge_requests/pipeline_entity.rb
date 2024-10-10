# frozen_string_literal: true

class MergeRequests::PipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :active?, as: :active
  expose :name

  expose :path do |pipeline|
    project_pipeline_path(pipeline.project, pipeline)
  end

  expose :project_path do |pipeline|
    project_path(pipeline.project)
  end

  expose :flags do
    expose :merged_result_pipeline?, as: :merge_request_pipeline # deprecated, use merged_result_pipeline going forward
    expose :merged_result_pipeline?, as: :merged_result_pipeline
    expose :merge_train_pipeline?, as: :merge_train_pipeline
  end

  expose :commit, using: CommitEntity

  expose :details do
    expose :event_type_name do |pipeline|
      pipeline.present.event_type_name
    end

    expose :artifacts do |pipeline, options|
      rel = pipeline.downloadable_artifacts
      project = pipeline.project

      allowed_to_read_artifacts = rel.select { |artifact| can?(request.current_user, :read_job_artifacts, artifact) }

      BuildArtifactEntity.represent(allowed_to_read_artifacts, options.merge(project: project))
    end

    expose :detailed_status, as: :status, with: DetailedStatusEntity do |pipeline|
      pipeline.detailed_status(request.current_user)
    end

    expose :stages, using: StageEntity

    expose :finished_at
  end

  # Coverage isn't always necessary (e.g. when displaying project pipelines in
  # the UI). Instead of creating an entirely different entity we just allow the
  # disabling of this specific field whenever necessary.
  expose :coverage, unless: proc { options[:disable_coverage] } do |pipeline|
    pipeline.present.coverage
  end

  expose :ref do
    expose :branch?, as: :branch
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
