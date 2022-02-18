# frozen_string_literal: true

module Ci
  class AfterRequeueJobService < ::BaseService
    def execute(processable)
      @processable = processable

      process_subsequent_jobs
      reset_source_bridge
    end

    private

    def process_subsequent_jobs
      dependent_jobs.each do |job|
        process(job)
      end
    end

    def reset_source_bridge
      @processable.pipeline.reset_source_bridge!(current_user)
    end

    def dependent_jobs
      stage_dependent_jobs
        .or(needs_dependent_jobs.except(:preload))
        .ordered_by_stage
    end

    def process(job)
      Gitlab::OptimisticLocking.retry_lock(job, name: 'ci_requeue_job') do |job|
        job.process(current_user)
      end
    end

    def stage_dependent_jobs
      skipped_jobs.after_stage(@processable.stage_idx)
    end

    def needs_dependent_jobs
      skipped_jobs.scheduling_type_dag.with_needs([@processable.name])
    end

    def skipped_jobs
      @skipped_jobs ||= @processable.pipeline.processables.skipped
    end
  end
end
