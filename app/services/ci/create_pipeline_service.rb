# frozen_string_literal: true

module Ci
  class CreatePipelineService < BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :pipeline

    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil, &seeds_block)
      @pipeline = Ci::Pipeline.new

      @pipeline.assign_attributes(
        source: source,
        project: project,
        ref: ref,
        sha: sha,
        before_sha: before_sha,
        tag: tag_exists?,
        trigger_requests: Array(trigger_request),
        user: current_user,
        pipeline_schedule: schedule,
        protected: protected_ref?,
        variables_attributes: Array(params[:variables_attributes])
      )

      @pipeline.set_config_source

      complete_block = -> () do
        schedule_head_pipeline_update
        cancel_pending_pipelines if project.auto_cancel_pending_pipelines?
        pipeline_created_counter.increment(source: source)
      end

      PopulatePipelineService.new(project, current_user).execute(pipeline, seeds_block, complete_block,
        save_on_errors: save_on_errors)

      pipeline
    end

    private

    def branch_exists?
      strong_memoize(:is_branch) do
        project.repository.branch_exists?(ref)
      end
    end

    def tag_exists?
      strong_memoize(:is_tag) do
        project.repository.tag_exists?(ref)
      end
    end

    def ref
      strong_memoize(:ref) do
        Gitlab::Git.ref_name(params[:ref])
      end
    end

    def sha
      strong_memoize(:sha) do
        project.commit(origin_sha || origin_ref).try(:id)
      end
    end

    def origin_sha
      params[:checkout_sha] || params[:after_sha]
    end

    def origin_ref
      params[:ref]
    end

    def before_sha
      params[:before_sha] || params[:checkout_sha] || Gitlab::Git::BLANK_SHA
    end

    def protected_ref?
      strong_memoize(:protected_ref) do
        project.protected_for?(ref)
      end
    end

    def commit
      @commit ||= project.commit(origin_sha || origin_ref)
    end

    def sha
      commit.try(:id)
    end

    def cancel_pending_pipelines
      Gitlab::OptimisticLocking.retry_lock(auto_cancelable_pipelines) do |cancelables|
        cancelables.find_each do |cancelable|
          cancelable.auto_cancel_running(pipeline)
        end
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def auto_cancelable_pipelines
      project.pipelines
        .where(ref: pipeline.ref)
        .where.not(id: pipeline.id)
        .where.not(sha: project.commit(pipeline.ref).try(:id))
        .created_or_pending
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics
        .counter(:pipelines_created_total, "Counter of pipelines created")
    end

    def schedule_head_pipeline_update
      related_merge_requests.each do |merge_request|
        UpdateHeadPipelineForMergeRequestWorker.perform_async(merge_request.id)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def related_merge_requests
      pipeline.project.source_of_merge_requests.opened.where(source_branch: pipeline.ref)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
