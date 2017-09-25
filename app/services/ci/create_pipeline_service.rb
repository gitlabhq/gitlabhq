module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Validate,
                Gitlab::Ci::Pipeline::Chain::Skip]

    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil)
      @pipeline = Ci::Pipeline.new(
        source: source,
        project: project,
        ref: ref,
        sha: sha,
        before_sha: before_sha,
        tag: tag?,
        trigger_requests: Array(trigger_request),
        user: current_user,
        pipeline_schedule: schedule,
        protected: project.protected_for?(ref)
      )

      command = OpenStruct.new(ignore_skip_ci: ignore_skip_ci,
                               save_incompleted: save_on_errors,
                               trigger_request: trigger_request,
                               schedule: schedule,
                               project: project,
                               current_user: current_user)

      sequence = SEQUENCE.map { |chain| chain.new(pipeline, command) }

      done = sequence.any? do |chain|
        chain.perform!
        chain.break?
      end

      update_merge_requests_head_pipeline if pipeline.persisted?

      return pipeline if done

      begin
        Ci::Pipeline.transaction do
          pipeline.save!

          yield(pipeline) if block_given?

          Ci::CreatePipelineStagesService
            .new(project, current_user)
            .execute(pipeline)
        end
      rescue ActiveRecord::RecordInvalid => e
        return error("Failed to persist the pipeline: #{e}")
      end

      update_merge_requests_head_pipeline if pipeline.persisted?
      cancel_pending_pipelines if project.auto_cancel_pending_pipelines?
      pipeline_created_counter.increment(source: source)

      pipeline.tap(&:process!)
    end

    private

    def commit
      @commit ||= project.commit(origin_sha || origin_ref)
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

    def tag?
      return @is_tag if defined?(@is_tag)

      @is_tag = project.repository.tag_exists?(ref)
    end

    def ref
      @ref ||= Gitlab::Git.ref_name(origin_ref)
    end

    def valid_sha?
      origin_sha && origin_sha != Gitlab::Git::BLANK_SHA
    end

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics
        .counter(:pipelines_created_total, "Counter of pipelines created")
    end
  end
end
