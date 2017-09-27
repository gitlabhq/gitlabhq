module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

<<<<<<< HEAD
    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil, mirror_update: false)
=======
    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Validate::Abilities,
                Gitlab::Ci::Pipeline::Chain::Validate::Repository,
                Gitlab::Ci::Pipeline::Chain::Validate::Config,
                Gitlab::Ci::Pipeline::Chain::Skip,
                Gitlab::Ci::Pipeline::Chain::Create].freeze

    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil, &block)
>>>>>>> upstream/master
      @pipeline = Ci::Pipeline.new(
        source: source,
        project: project,
        ref: ref,
        sha: sha,
        before_sha: before_sha,
        tag: tag_exists?,
        trigger_requests: Array(trigger_request),
        user: current_user,
        pipeline_schedule: schedule,
        protected: project.protected_for?(ref)
      )

<<<<<<< HEAD
      result = validate_project_and_git_items(mirror_update: mirror_update) ||
        validate_pipeline(ignore_skip_ci: ignore_skip_ci,
                          save_on_errors: save_on_errors)
=======
      command = OpenStruct.new(ignore_skip_ci: ignore_skip_ci,
                               save_incompleted: save_on_errors,
                               seeds_block: block,
                               project: project,
                               current_user: current_user)
>>>>>>> upstream/master

      sequence = Gitlab::Ci::Pipeline::Chain::Sequence
        .new(pipeline, command, SEQUENCE)

      sequence.build! do |pipeline, sequence|
        update_merge_requests_head_pipeline if pipeline.persisted?

        if sequence.complete?
          cancel_pending_pipelines if project.auto_cancel_pending_pipelines?
          pipeline_created_counter.increment(source: source)

          pipeline.process!
        end
      end
    end

    private

<<<<<<< HEAD
    def validate_project_and_git_items(mirror_update: false)
      unless project.builds_enabled?
        return error('Pipeline is disabled')
      end

      if mirror_update && !project.mirror_trigger_builds?
        return error('Pipeline is disabled for mirror updates')
      end

      unless allowed_to_trigger_pipeline?
        if can?(current_user, :create_pipeline, project)
          return error("Insufficient permissions for protected ref '#{ref}'")
        else
          return error('Insufficient permissions to create a new pipeline')
        end
      end

      unless branch? || tag?
        return error('Reference not found')
      end

      unless commit
        return error('Commit not found')
      end
    end

    def validate_pipeline(ignore_skip_ci:, save_on_errors:)
      unless pipeline.config_processor
        unless pipeline.ci_yaml_file
          return error("Missing #{pipeline.ci_yaml_file_path} file")
        end
        return error(pipeline.yaml_errors, save: save_on_errors)
      end

      if !ignore_skip_ci && skip_ci?
        pipeline.skip if save_on_errors
        return pipeline
      end

      unless pipeline.has_stage_seeds?
        return error('No stages / jobs for this pipeline.')
      end
    end

    def allowed_to_trigger_pipeline?
      if current_user
        allowed_to_create?
      else # legacy triggers don't have a corresponding user
        !project.protected_for?(ref)
      end
=======
    def commit
      @commit ||= project.commit(origin_sha || origin_ref)
>>>>>>> upstream/master
    end

    def sha
      commit.try(:id)
    end

    def update_merge_requests_head_pipeline
      return unless pipeline.latest?

      MergeRequest.where(source_project: @pipeline.project, source_branch: @pipeline.ref)
        .update_all(head_pipeline_id: @pipeline.id)
    end

    def cancel_pending_pipelines
      Gitlab::OptimisticLocking.retry_lock(auto_cancelable_pipelines) do |cancelables|
        cancelables.find_each do |cancelable|
          cancelable.auto_cancel_running(pipeline)
        end
      end
    end

    def auto_cancelable_pipelines
      project.pipelines
        .where(ref: pipeline.ref)
        .where.not(id: pipeline.id)
        .where.not(sha: project.repository.sha_from_ref(pipeline.ref))
        .created_or_pending
    end

    def before_sha
      params[:checkout_sha] || params[:before] || Gitlab::Git::BLANK_SHA
    end

    def origin_sha
      params[:checkout_sha] || params[:after]
    end

    def origin_ref
      params[:ref]
    end

    def tag_exists?
      project.repository.tag_exists?(ref)
    end

    def ref
      @ref ||= Gitlab::Git.ref_name(origin_ref)
    end

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics
        .counter(:pipelines_created_total, "Counter of pipelines created")
    end
  end
end
