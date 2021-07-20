# frozen_string_literal: true

module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

    CreateError = Class.new(StandardError)

    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Build,
                Gitlab::Ci::Pipeline::Chain::Build::Associations,
                Gitlab::Ci::Pipeline::Chain::Validate::Abilities,
                Gitlab::Ci::Pipeline::Chain::Validate::Repository,
                Gitlab::Ci::Pipeline::Chain::Validate::SecurityOrchestrationPolicy,
                Gitlab::Ci::Pipeline::Chain::Config::Content,
                Gitlab::Ci::Pipeline::Chain::Config::Process,
                Gitlab::Ci::Pipeline::Chain::Validate::AfterConfig,
                Gitlab::Ci::Pipeline::Chain::RemoveUnwantedChatJobs,
                Gitlab::Ci::Pipeline::Chain::Skip,
                Gitlab::Ci::Pipeline::Chain::SeedBlock,
                Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules,
                Gitlab::Ci::Pipeline::Chain::Seed,
                Gitlab::Ci::Pipeline::Chain::Limit::Size,
                Gitlab::Ci::Pipeline::Chain::Limit::Deployments,
                Gitlab::Ci::Pipeline::Chain::Validate::External,
                Gitlab::Ci::Pipeline::Chain::Populate,
                Gitlab::Ci::Pipeline::Chain::StopDryRun,
                Gitlab::Ci::Pipeline::Chain::Create,
                Gitlab::Ci::Pipeline::Chain::Limit::Activity,
                Gitlab::Ci::Pipeline::Chain::Limit::JobActivity,
                Gitlab::Ci::Pipeline::Chain::CancelPendingPipelines,
                Gitlab::Ci::Pipeline::Chain::Metrics,
                Gitlab::Ci::Pipeline::Chain::TemplateUsage,
                Gitlab::Ci::Pipeline::Chain::Pipeline::Process].freeze

    # Create a new pipeline in the specified project.
    #
    # @param [Symbol] source                             What event (Ci::Pipeline.sources) triggers the pipeline
    #                                                    creation.
    # @param [Boolean] ignore_skip_ci                    Whether skipping a pipeline creation when `[skip ci]` comment
    #                                                    is present in the commit body
    # @param [Boolean] save_on_errors                    Whether persisting an invalid pipeline when it encounters an
    #                                                    error during creation (e.g. invalid yaml)
    # @param [Ci::TriggerRequest] trigger_request        The pipeline trigger triggers the pipeline creation.
    # @param [Ci::PipelineSchedule] schedule             The pipeline schedule triggers the pipeline creation.
    # @param [MergeRequest] merge_request                The merge request triggers the pipeline creation.
    # @param [ExternalPullRequest] external_pull_request The external pull request triggers the pipeline creation.
    # @param [Ci::Bridge] bridge                         The bridge job that triggers the downstream pipeline creation.
    # @param [String] content                            The content of .gitlab-ci.yml to override the default config
    #                                                    contents (e.g. .gitlab-ci.yml in repostiry). Mainly used for
    #                                                    generating a dangling pipeline.
    #
    # @return [Ci::Pipeline]                             The created Ci::Pipeline object.
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
        **extra_options(**options))

      # Ensure we never persist the pipeline when dry_run: true
      @pipeline.readonly! if command.dry_run?

      Gitlab::Ci::Pipeline::Chain::Sequence
        .new(pipeline, command, SEQUENCE)
        .build!

      if pipeline.persisted?
        schedule_head_pipeline_update
        create_namespace_onboarding_action
      else
        # If pipeline is not persisted, try to recover IID
        pipeline.reset_project_iid
      end

      if error_message = pipeline.full_error_messages.presence || pipeline.failure_reason.presence
        ServiceResponse.error(message: error_message, payload: pipeline)
      else
        ServiceResponse.success(payload: pipeline)
      end
    end
    # rubocop: enable Metrics/ParameterLists

    def execute!(*args, &block)
      source = args[0]
      params = Hash(args[1])

      execute(source, **params, &block).tap do |response|
        unless response.payload.persisted?
          raise CreateError, pipeline.full_error_messages
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

    def schedule_head_pipeline_update
      pipeline.all_merge_requests.opened.each do |merge_request|
        UpdateHeadPipelineForMergeRequestWorker.perform_async(merge_request.id)
      end
    end

    def create_namespace_onboarding_action
      Namespaces::OnboardingPipelineCreatedWorker.perform_async(project.namespace_id)
    end

    def extra_options(content: nil, dry_run: false)
      { content: content, dry_run: dry_run }
    end
  end
end

Ci::CreatePipelineService.prepend_mod_with('Ci::CreatePipelineService')
