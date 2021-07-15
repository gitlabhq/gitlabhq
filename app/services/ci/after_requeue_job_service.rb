# frozen_string_literal: true

module Ci
  class AfterRequeueJobService < ::BaseService
    def execute(processable)
      process_subsequent_jobs(processable)
      reset_source_bridge(processable)
    end

    private

    def process_subsequent_jobs(processable)
      if Feature.enabled?(:ci_same_stage_job_needs, processable.project, default_enabled: :yaml)
        (stage_dependent_jobs(processable) | needs_dependent_jobs(processable))
        .each do |processable|
          process(processable)
        end
      else
        skipped_jobs(processable).after_stage(processable.stage_idx)
          .find_each do |job|
          process(job)
        end
      end
    end

    def reset_source_bridge(processable)
      processable.pipeline.reset_source_bridge!(current_user)
    end

    def process(processable)
      Gitlab::OptimisticLocking.retry_lock(processable, name: 'ci_requeue_job') do |processable|
        processable.process(current_user)
      end
    end

    def skipped_jobs(processable)
      processable.pipeline.processables.skipped
    end

    def stage_dependent_jobs(processable)
      skipped_jobs(processable).scheduling_type_stage.after_stage(processable.stage_idx)
    end

    def needs_dependent_jobs(processable)
      skipped_jobs(processable).scheduling_type_dag.with_needs([processable.name])
    end
  end
end
