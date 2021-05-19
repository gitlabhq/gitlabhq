# frozen_string_literal: true

module Ci
  class CreateWebIdeTerminalService < ::BaseService
    include ::Gitlab::Utils::StrongMemoize

    TerminalCreationError = Class.new(StandardError)

    TERMINAL_NAME = 'terminal'

    attr_reader :terminal

    def execute
      check_access!
      validate_params!
      load_terminal_config!

      pipeline = create_pipeline!
      success(pipeline: pipeline)
    rescue TerminalCreationError => e
      error(e.message)
    rescue ActiveRecord::RecordInvalid => e
      error("Failed to persist the pipeline: #{e.message}")
    end

    private

    def create_pipeline!
      build_pipeline.tap do |pipeline|
        pipeline.stages << terminal_stage_seed(pipeline).to_resource

        # Project iid must be called outside a transaction, so we ensure it is set here
        # otherwise it may be set within the save! which it will lock the InternalId row for the whole transaction
        pipeline.ensure_project_iid!

        pipeline.save!

        Ci::ProcessPipelineService
          .new(pipeline)
          .execute

        pipeline_created_counter.increment(source: :webide)
      end
    end

    def build_pipeline
      Ci::Pipeline.new(
        project: project,
        user: current_user,
        source: :webide,
        config_source: :webide_source,
        ref: ref,
        sha: sha,
        tag: false,
        before_sha: Gitlab::Git::BLANK_SHA
      )
    end

    def terminal_stage_seed(pipeline)
      attributes = {
        name: TERMINAL_NAME,
        index: 0,
        builds: [terminal_build_seed]
      }

      seed_context = Gitlab::Ci::Pipeline::Seed::Context.new(pipeline)
      Gitlab::Ci::Pipeline::Seed::Stage.new(seed_context, attributes, [])
    end

    def terminal_build_seed
      terminal.merge(
        name: TERMINAL_NAME,
        stage: TERMINAL_NAME,
        user: current_user,
        scheduling_type: :stage)
    end

    def load_terminal_config!
      result = ::Ide::TerminalConfigService.new(project, current_user, sha: sha).execute
      raise TerminalCreationError, result[:message] if result[:status] != :success

      @terminal = result[:terminal]
      raise TerminalCreationError, 'Terminal is not configured' unless terminal
    end

    def validate_params!
      unless sha
        raise TerminalCreationError, 'Ref does not exist'
      end

      unless branch_exists?
        raise TerminalCreationError, 'Ref needs to be a branch'
      end
    end

    def check_access!
      unless can?(current_user, :create_web_ide_terminal, project)
        raise TerminalCreationError, 'Insufficient permissions to create a terminal'
      end

      if terminal_active?
        raise TerminalCreationError, 'There is already a terminal running'
      end
    end

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics
        .counter(:pipelines_created_total, "Counter of pipelines created")
    end

    def terminal_active?
      project.active_webide_pipelines(user: current_user).exists?
    end

    def ref
      strong_memoize(:ref) do
        Gitlab::Git.ref_name(params[:ref])
      end
    end

    def branch_exists?
      project.repository.branch_exists?(ref)
    end

    def sha
      project.commit(params[:ref]).try(:id)
    end
  end
end
