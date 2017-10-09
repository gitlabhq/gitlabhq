module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Build,
                Gitlab::Ci::Pipeline::Chain::Validate::Abilities,
                Gitlab::Ci::Pipeline::Chain::Validate::Repository,
                Gitlab::Ci::Pipeline::Chain::Validate::Config,
                Gitlab::Ci::Pipeline::Chain::Skip,
                Gitlab::Ci::Pipeline::Chain::Create].freeze

    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil, &block)
      @pipeline = Ci::Pipeline.new

      command = OpenStruct.new(source: source,
                               origin_ref: params[:ref],
                               checkout_sha: params[:checkout_sha],
                               after_sha: params[:after],
                               before_sha: params[:before],
                               trigger_request: trigger_request,
                               schedule: schedule,
                               ignore_skip_ci: ignore_skip_ci,
                               save_incompleted: save_on_errors,
                               seeds_block: block,
                               project: project,
                               current_user: current_user)

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

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics
        .counter(:pipelines_created_total, "Counter of pipelines created")
    end
  end
end
