# frozen_string_literal: true

module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

    CreateError = Class.new(StandardError)

    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Build,
                Gitlab::Ci::Pipeline::Chain::Validate::Abilities,
                Gitlab::Ci::Pipeline::Chain::Validate::Repository,
                Gitlab::Ci::Pipeline::Chain::Config::Content,
                Gitlab::Ci::Pipeline::Chain::Config::Process,
                Gitlab::Ci::Pipeline::Chain::RemoveUnwantedChatJobs,
                Gitlab::Ci::Pipeline::Chain::Skip,
                Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules,
                Gitlab::Ci::Pipeline::Chain::Seed,
                Gitlab::Ci::Pipeline::Chain::Limit::Size,
                Gitlab::Ci::Pipeline::Chain::Validate::External,
                Gitlab::Ci::Pipeline::Chain::Populate,
                Gitlab::Ci::Pipeline::Chain::Create,
                Gitlab::Ci::Pipeline::Chain::Limit::Activity,
                Gitlab::Ci::Pipeline::Chain::Limit::JobActivity].freeze

    # rubocop: disable Metrics/ParameterLists
    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil, merge_request: nil, external_pull_request: nil, bridge: nil, **options, &block)
      @pipeline = Ci::Pipeline.new

      command = Gitlab::Ci::Pipeline::Chain::Command.new(
        source: source,
        origin_ref: params[:ref],
        checkout_sha: params[:checkout_sha],
        after_sha: params[:after],
        before_sha: params[:before],          # The base SHA of the source branch (i.e merge_request.diff_base_sha).
        source_sha: params[:source_sha],      # The HEAD SHA of the source branch (i.e merge_request.diff_head_sha).
        target_sha: params[:target_sha],      # The HEAD SHA of the target branch.
        trigger_request: trigger_request,
        schedule: schedule,
        merge_request: merge_request,
        external_pull_request: external_pull_request,
        ignore_skip_ci: ignore_skip_ci,
        save_incompleted: save_on_errors,
        seeds_block: block,
        variables_attributes: params[:variables_attributes],
        project: project,
        current_user: current_user,
        push_options: params[:push_options] || {},
        chat_data: params[:chat_data],
        bridge: bridge,
        **extra_options(options))

      sequence = Gitlab::Ci::Pipeline::Chain::Sequence
        .new(pipeline, command, SEQUENCE)

      sequence.build! do |pipeline, sequence|
        schedule_head_pipeline_update

        if sequence.complete?
          cancel_pending_pipelines if project.auto_cancel_pending_pipelines?
          pipeline_created_counter.increment(source: source)

          Ci::ProcessPipelineService
            .new(pipeline)
            .execute
        end
      end

      # If pipeline is not persisted, try to recover IID
      pipeline.reset_project_iid unless pipeline.persisted? ||
          Feature.disabled?(:ci_pipeline_rewind_iid, project, default_enabled: true)

      pipeline
    end
    # rubocop: enable Metrics/ParameterLists

    def execute!(*args, &block)
      execute(*args, &block).tap do |pipeline|
        unless pipeline.persisted?
          raise CreateError, pipeline.error_messages
        end
      end
    end

    private

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
      # TODO: Introduced by https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/23464
      if Feature.enabled?(:ci_support_interruptible_pipelines, project, default_enabled: true)
        project.ci_pipelines
          .where(ref: pipeline.ref)
          .where.not(id: pipeline.same_family_pipeline_ids)
          .where.not(sha: project.commit(pipeline.ref).try(:id))
          .alive_or_scheduled
          .with_only_interruptible_builds
      else
        project.ci_pipelines
          .where(ref: pipeline.ref)
          .where.not(id: pipeline.same_family_pipeline_ids)
          .where.not(sha: project.commit(pipeline.ref).try(:id))
          .created_or_pending
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics
        .counter(:pipelines_created_total, "Counter of pipelines created")
    end

    def schedule_head_pipeline_update
      pipeline.all_merge_requests.opened.each do |merge_request|
        UpdateHeadPipelineForMergeRequestWorker.perform_async(merge_request.id)
      end
    end

    def extra_options(options = {})
      # In Ruby 2.4, even when options is empty, f(**options) doesn't work when f
      # doesn't have any parameters. We reproduce the Ruby 2.5 behavior by
      # checking explicitly that no arguments are given.
      raise ArgumentError if options.any?

      {} # overridden in EE
    end
  end
end

Ci::CreatePipelineService.prepend_if_ee('EE::Ci::CreatePipelineService')
