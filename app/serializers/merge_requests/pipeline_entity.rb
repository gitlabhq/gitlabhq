# frozen_string_literal: true

class MergeRequests::PipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :active?, as: :active

  expose :path do |pipeline|
    project_pipeline_path(pipeline.project, pipeline)
  end

  expose :flags do
    expose :merged_result_pipeline?, as: :merge_request_pipeline
  end

  expose :commit, using: CommitEntity

  expose :details do
    expose :name do |pipeline|
      pipeline.present.name
    end

    expose :artifacts do |pipeline, options|
      rel = pipeline.downloadable_artifacts

      if Feature.enabled?(:non_public_artifacts, type: :development)
        rel = rel.select { |artifact| can?(request.current_user, :read_job_artifacts, artifact.job) }
      end

      BuildArtifactEntity.represent(rel, options.merge(project: pipeline.project))
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
  expose :coverage, unless: proc { options[:disable_coverage] }

  expose :ref do
    expose :branch?, as: :branch
  end

  expose :triggered_by_pipeline, as: :triggered_by, with: TriggeredPipelineEntity
  expose :triggered_pipelines, as: :triggered, using: TriggeredPipelineEntity
end
