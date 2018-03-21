module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

    SEQUENCE = [Gitlab::Ci::Pipeline::Chain::Build,
                EE::Gitlab::Ci::Pipeline::Chain::RemoveUnwantedChatJobs,
                Gitlab::Ci::Pipeline::Chain::Validate::Abilities,
                Gitlab::Ci::Pipeline::Chain::Validate::Repository,
                Gitlab::Ci::Pipeline::Chain::Validate::Config,
                Gitlab::Ci::Pipeline::Chain::Skip,
                EE::Gitlab::Ci::Pipeline::Chain::Limit::Size,
                Gitlab::Ci::Pipeline::Chain::Populate,
                Gitlab::Ci::Pipeline::Chain::Create,
                EE::Gitlab::Ci::Pipeline::Chain::Limit::Activity].freeze
                Gitlab::Ci::Pipeline::Chain::Create].freeze

    def execute(source, ignore_skip_ci: false, save_on_errors: true, trigger_request: nil, schedule: nil, mirror_update: false, &block)
      @pipeline = Ci::Pipeline.new

      command = Gitlab::Ci::Pipeline::Chain::Command.new(
        source: source,
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
        current_user: current_user,

        # EE specific
        allow_mirror_update: mirror_update,
        chat_data: params[:chat_data]
      )

      sequence = Gitlab::Ci::Pipeline::Chain::Sequence
        .new(pipeline, command, SEQUENCE)

      sequence.build! do |pipeline, sequence|
        schedule_head_pipeline_update

        if sequence.complete?
          cancel_pending_pipelines if project.auto_cancel_pending_pipelines?
          pipeline_created_counter.increment(source: source)

          pipeline.process!
        end
      end

      pipeline
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

    def schedule_head_pipeline_update
      related_merge_requests.each do |merge_request|
        UpdateHeadPipelineForMergeRequestWorker.perform_async(merge_request.id)
      end
    end

    def related_merge_requests
      pipeline.project.source_of_merge_requests.opened.where(source_branch: pipeline.ref)
    end
  end
end
