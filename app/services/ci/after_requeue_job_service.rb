# frozen_string_literal: true

module Ci
  class AfterRequeueJobService < ::BaseService
    def execute(processable)
      process_subsequent_jobs(processable)
      reset_ancestor_bridges(processable)
    end

    private

    def process_subsequent_jobs(processable)
      processable.pipeline.processables.skipped.after_stage(processable.stage_idx).find_each do |processable|
        process(processable)
      end
    end

    def reset_ancestor_bridges(processable)
      processable.pipeline.reset_ancestor_bridges!
    end

    def process(processable)
      Gitlab::OptimisticLocking.retry_lock(processable, name: 'ci_requeue_job') do |processable|
        processable.process(current_user)
      end
    end
  end
end
