# frozen_string_literal: true

module Ci
  class CreateCommitStatusService < BaseService
    include ::Gitlab::ExclusiveLeaseHelpers
    include ::Gitlab::Utils::StrongMemoize
    include ::Services::ReturnServiceResponses

    delegate :sha, to: :commit

    # Default number of pipelines to return
    DEFAULT_LIMIT_PIPELINES = 100

    def execute(optional_commit_status_params:)
      in_lock(pipeline_lock_key, **pipeline_lock_params) do
        @optional_commit_status_params = optional_commit_status_params
        unsafe_execute
      end
    end

    private

    attr_reader :pipeline, :stage, :commit_status, :optional_commit_status_params

    def unsafe_execute
      result = validate
      return result if result&.error?

      @pipeline = first_matching_pipeline || create_pipeline
      return forbidden unless ::Ability.allowed?(current_user, :update_pipeline, pipeline)

      @stage = find_or_create_external_stage
      @commit_status = find_or_build_external_commit_status

      return bad_request(commit_status.errors.messages) if commit_status.invalid?

      response = add_or_update_external_job

      return bad_request(response.message) if response.error?

      response
    end

    def validate
      return not_found('Commit') if commit.blank?
      return bad_request('State is required') if params[:state].blank?
      return not_found('References for commit') if ref.blank?

      return unless params[:pipeline_id] && !first_matching_pipeline

      not_found("Pipeline for pipeline_id, sha and ref")
    end

    def ref
      params[:ref] || first_matching_pipeline&.ref ||
        repository.branch_names_contains(sha).first
    end
    strong_memoize_attr :ref

    def commit
      project.commit(params[:sha])
    end
    strong_memoize_attr :commit

    def first_matching_pipeline
      limit = params[:pipeline_id] ? nil : DEFAULT_LIMIT_PIPELINES
      pipelines = project.ci_pipelines.newest_first(sha: sha, limit: limit)
      pipelines = pipelines.for_ref(params[:ref]) if params[:ref]
      pipelines = pipelines.id_in(params[:pipeline_id]) if params[:pipeline_id]
      pipelines.first
    end
    strong_memoize_attr :first_matching_pipeline

    def name
      params[:name] || params[:context] || 'default'
    end

    def create_pipeline
      project.ci_pipelines.build(
        source: :external,
        sha: sha,
        ref: ref,
        user: current_user,
        protected: project.protected_for?(ref)
      ).tap do |new_pipeline|
        new_pipeline.ensure_project_iid!
        new_pipeline.save!

        Gitlab::EventStore.publish(
          Ci::PipelineCreatedEvent.new(data: { pipeline_id: new_pipeline.id })
        )
      end
    end

    def find_or_create_external_stage
      pipeline.stages.safe_find_or_create_by!(name: 'external') do |stage| # rubocop:disable Performance/ActiveRecordSubtransactionMethods
        stage.position = ::GenericCommitStatus::EXTERNAL_STAGE_IDX
        stage.project = project
      end
    end

    def find_or_build_external_commit_status
      ::GenericCommitStatus.running_or_pending.find_or_initialize_by( # rubocop:disable CodeReuse/ActiveRecord
        project: project,
        pipeline: pipeline,
        name: name,
        ref: ref,
        user: current_user,
        protected: project.protected_for?(ref),
        ci_stage: stage,
        stage_idx: stage.position,
        partition_id: pipeline.partition_id
      ).tap do |new_commit_status|
        new_commit_status.assign_attributes(optional_commit_status_params)
      end
    end

    def add_or_update_external_job
      ::Ci::Pipelines::AddJobService.new(pipeline).execute!(commit_status) do |job|
        apply_job_state!(job)
      end
    end

    def apply_job_state!(job)
      case params[:state]
      when 'pending'
        job.enqueue!
      when 'running'
        job.enqueue
        job.run!
      when 'success'
        job.success!
      when 'failed'
        job.drop!(:api_failure)
      when 'canceled'
        job.cancel!
      when 'skipped'
        job.skip!
      else
        raise('invalid state')
      end
    end

    def pipeline_lock_key
      "api:commit_statuses:project:#{project.id}:sha:#{params[:sha]}"
    end

    def pipeline_lock_params
      {
        ttl: 5.seconds,
        sleep_sec: 0.1.seconds,
        retries: 20
      }
    end

    def not_found(message)
      error("404 #{message} Not Found", :not_found)
    end

    def bad_request(message)
      error(message, :bad_request)
    end

    def forbidden
      error("403 Forbidden", :forbidden)
    end
  end
end
