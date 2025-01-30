# frozen_string_literal: true

class Ci::PipelineEntity < Grape::Entity
  include RequestAwareEntity
  include Gitlab::Utils::StrongMemoize

  delegate :event_type_name, :failure_reason, :coverage, to: :presented_pipeline

  expose :id
  expose :iid
  expose :user, using: UserEntity
  expose :active?, as: :active
  expose :name

  # Coverage isn't always necessary (e.g. when displaying project pipelines in
  # the UI). Instead of creating an entirely different entity we just allow the
  # disabling of this specific field whenever necessary.
  expose :coverage, unless: proc { options[:disable_coverage] }
  expose :source

  expose :created_at, :updated_at

  expose :path do |pipeline|
    project_pipeline_path(pipeline.project, pipeline)
  end

  expose :flags do
    expose :stuck?, as: :stuck
    expose :auto_devops_source?, as: :auto_devops
    expose :merge_request?, as: :merge_request
    expose :has_yaml_errors?, as: :yaml_errors
    expose :can_retry?, as: :retryable
    expose :can_cancel?, as: :cancelable
    expose :failure_reason?, as: :failure_reason
    expose :detached_merge_request_pipeline?, as: :detached_merge_request_pipeline
    expose :merged_result_pipeline?, as: :merge_request_pipeline # deprecated, use merged_result_pipeline going forward
    expose :merged_result_pipeline?, as: :merged_result_pipeline
    expose :type, as: :type
  end

  expose :details do
    expose :detailed_status, as: :status, with: DetailedStatusEntity
    expose :stages, using: StageEntity
    expose :duration
    expose :finished_at
    expose :event_type_name
  end

  expose :merge_request, if: ->(*) { has_presentable_merge_request? }, with: MergeRequestForPipelineEntity do |pipeline|
    pipeline.merge_request.present(current_user: request.current_user)
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
    expose :merge_request?, as: :merge_request
  end

  expose :commit, using: CommitEntity
  expose :merge_request_event_type, if: ->(pipeline, _) { pipeline.merge_request? }
  expose :source_sha, if: ->(pipeline, _) { pipeline.merged_result_pipeline? }
  expose :target_sha, if: ->(pipeline, _) { pipeline.merged_result_pipeline? }
  expose :yaml_errors, if: ->(pipeline, _) { pipeline.has_yaml_errors? }
  expose :failure_reason, if: ->(pipeline, _) { pipeline.failure_reason? }

  expose :retry_path, if: ->(*) { can_retry? } do |pipeline|
    retry_project_pipeline_path(pipeline.project, pipeline)
  end

  expose :cancel_path, if: ->(*) { can_cancel? } do |pipeline|
    cancel_project_pipeline_path(pipeline.project, pipeline)
  end

  expose :delete_path, if: ->(*) { can_delete? } do |pipeline|
    project_pipeline_path(pipeline.project, pipeline)
  end

  expose :failed_builds,
    if: ->(_, options) { !options[:disable_failed_builds] && can_retry? },
    using: Ci::JobEntity do |pipeline|
    pipeline.failed_builds.each do |build|
      build.project = pipeline.project
    end
  end

  expose :failed_builds_count do |pipeline|
    if options[:disable_failed_builds]
      pipeline.limited_failed_builds.size
    else
      pipeline.failed_builds.size
    end
  end

  expose :pipeline_schedule, using: Ci::PipelineScheduleEntity

  private

  alias_method :pipeline, :object

  def can_retry?
    can?(request.current_user, :update_pipeline, pipeline) &&
      pipeline.retryable?
  end

  def can_cancel?
    can?(request.current_user, :cancel_pipeline, pipeline) &&
      pipeline.cancelable?
  end

  def can_delete?
    can?(request.current_user, :destroy_pipeline, pipeline)
  end

  def has_presentable_merge_request?
    pipeline.merge_request? &&
      can?(request.current_user, :read_merge_request, pipeline.merge_request)
  end

  def detailed_status
    pipeline.detailed_status(request.current_user)
  end

  def presented_pipeline
    strong_memoize(:presented_pipeline) do
      pipeline.present
    end
  end
end

Ci::PipelineEntity.prepend_mod_with('Ci::PipelineEntity')
