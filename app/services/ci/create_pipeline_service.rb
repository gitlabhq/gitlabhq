# frozen_string_literal: true

module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline, :logger

    LOG_MAX_DURATION_THRESHOLD = 3.seconds
    LOG_MAX_PIPELINE_SIZE = 2_000
    LOG_MAX_CREATION_THRESHOLD = 20.seconds
    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Build,
      Gitlab::Ci::Pipeline::Chain::Validate::Abilities,
      Gitlab::Ci::Pipeline::Chain::Validate::Repository,
      Gitlab::Ci::Pipeline::Chain::Build::Associations,
      Gitlab::Ci::Pipeline::Chain::Limit::RateLimit,
      Gitlab::Ci::Pipeline::Chain::Validate::SecurityOrchestrationPolicy,
      Gitlab::Ci::Pipeline::Chain::AssignPartition,
      Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::EvaluatePolicies,
      Gitlab::Ci::Pipeline::Chain::Skip,
      Gitlab::Ci::Pipeline::Chain::Config::Content,
      Gitlab::Ci::Pipeline::Chain::Config::Process,
      Gitlab::Ci::Pipeline::Chain::Validate::AfterConfig,
      Gitlab::Ci::Pipeline::Chain::RemoveUnwantedChatJobs,
      Gitlab::Ci::Pipeline::Chain::SeedBlock,
      Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules,
      Gitlab::Ci::Pipeline::Chain::Seed,
      Gitlab::Ci::Pipeline::Chain::Limit::Size,
      Gitlab::Ci::Pipeline::Chain::Limit::ActiveJobs,
      Gitlab::Ci::Pipeline::Chain::Limit::Deployments,
      Gitlab::Ci::Pipeline::Chain::Validate::External,
      Gitlab::Ci::Pipeline::Chain::SetBuildSources,
      Gitlab::Ci::Pipeline::Chain::Populate,
      Gitlab::Ci::Pipeline::Chain::PopulateMetadata,
      Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::ApplyPolicies,
      Gitlab::Ci::Pipeline::Chain::StopDryRun,
      Gitlab::Ci::Pipeline::Chain::EnsureEnvironments,
      Gitlab::Ci::Pipeline::Chain::EnsureResourceGroups,
      Gitlab::Ci::Pipeline::Chain::Create,
      Gitlab::Ci::Pipeline::Chain::CreateCrossDatabaseAssociations,
      Gitlab::Ci::Pipeline::Chain::CancelPendingPipelines,
      Gitlab::Ci::Pipeline::Chain::Metrics,
      Gitlab::Ci::Pipeline::Chain::TemplateUsage,
      Gitlab::Ci::Pipeline::Chain::ComponentUsage,
      Gitlab::Ci::Pipeline::Chain::KeywordUsage,
      Gitlab::Ci::Pipeline::Chain::Pipeline::Process].freeze

    # Create a new pipeline in the specified project.
    #
    # @param [Symbol] source                                  What event (Ci::Pipeline.sources) triggers the pipeline
    #                                                         creation.
    # @param [Boolean] ignore_skip_ci                         Whether skipping a pipeline creation when `[skip ci]` comment
    #                                                         is present in the commit body
    # @param [Boolean] save_on_errors                         Whether persisting an invalid pipeline when it encounters an
    #                                                         error during creation (e.g. invalid yaml)
    # @param [Ci::TriggerRequest] trigger_request             The pipeline trigger triggers the pipeline creation.
    # @param [Ci::PipelineSchedule] schedule                  The pipeline schedule triggers the pipeline creation.
    # @param [MergeRequest] merge_request                     The merge request triggers the pipeline creation.
    # @param [Ci::ExternalPullRequest] external_pull_request  The external pull request triggers the pipeline creation.
    # @param [Ci::Bridge] bridge                              The bridge job that triggers the downstream pipeline creation.
    # @param [String] content                                 The content of .gitlab-ci.yml to override the default config
    #                                                         contents (e.g. .gitlab-ci.yml in repostiry). Mainly used for
    #                                                         generating a dangling pipeline.
    #
    # @return [Ci::Pipeline]                                  The created Ci::Pipeline object.
    # rubocop: disable Metrics/ParameterLists, Metrics/AbcSize
    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil, merge_request: nil, external_pull_request: nil, bridge: nil, **options, &block)
      @logger = build_logger
      @command_logger = Gitlab::Ci::Pipeline::CommandLogger.new
      @pipeline = Ci::Pipeline.new

      validate_options!(options)

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
        logger: @logger,
        partition_id: params[:partition_id],
        **extra_options(**options))

      # Ensure we never persist the pipeline when dry_run: true
      @pipeline.readonly! if command.dry_run?

      Gitlab::Ci::Pipeline::Chain::Sequence
        .new(pipeline, command, SEQUENCE)
        .build!

      if pipeline.persisted?
        Gitlab::EventStore.publish(
          Ci::PipelineCreatedEvent.new(data: { pipeline_id: pipeline.id })
        )

        after_successful_creation_hook
      else
        # If pipeline is not persisted, try to recover IID
        pipeline.reset_project_iid
      end

      if error_message = pipeline.full_error_messages.presence || pipeline.failure_reason.presence
        ::Ci::PipelineCreation::Requests.failed(params[:pipeline_creation_request], error_message)

        ServiceResponse.error(message: error_message, payload: pipeline)
      else
        ::Ci::PipelineCreation::Requests.succeeded(params[:pipeline_creation_request], pipeline.id)

        ServiceResponse.success(payload: pipeline)
      end

    ensure
      @logger.commit(pipeline: pipeline, caller: self.class.name)
      @command_logger.commit(pipeline: pipeline, command: command) if command
    end
    # rubocop: enable Metrics/ParameterLists, Metrics/AbcSize

    def execute_async(source, options)
      pipeline_creation_request = ::Ci::PipelineCreation::Requests.start_for_project(project)
      creation_params = params.merge(pipeline_creation_request: pipeline_creation_request)

      ::CreatePipelineWorker.perform_async(
        project.id, current_user.id, params[:ref], source.to_s,
        options.stringify_keys, creation_params.except(:ref).stringify_keys
      )

      ServiceResponse.success(payload: pipeline_creation_request['id'])
    end

    private

    def after_successful_creation_hook
      # overridden in EE
    end

    # rubocop:disable Gitlab/NoCodeCoverageComment
    # :nocov: Tested in FOSS and fully overridden and tested in EE
    def validate_options!(_)
      raise ArgumentError, "Param `partition_id` is not allowed" if params[:partition_id]
    end
    # :nocov:
    # rubocop:enable Gitlab/NoCodeCoverageComment

    def extra_options(content: nil, dry_run: false)
      { content: content, dry_run: dry_run }
    end

    def build_logger
      Gitlab::Ci::Pipeline::Logger.new(project: project) do |l|
        l.log_when do |observations|
          observations.any? do |name, observation|
            name.to_s.end_with?('duration_s') &&
              Array(observation).max >= LOG_MAX_DURATION_THRESHOLD
          end
        end

        l.log_when do |observations|
          count = observations['pipeline_size_count']
          next false unless count

          count >= LOG_MAX_PIPELINE_SIZE
        end

        l.log_when do |observations|
          duration = observations['pipeline_creation_duration_s']
          next false unless duration

          duration >= LOG_MAX_CREATION_THRESHOLD
        end
      end
    end
  end
end

Ci::CreatePipelineService.prepend_mod_with('Ci::CreatePipelineService')
