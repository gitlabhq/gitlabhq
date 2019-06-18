# frozen_string_literal: true

module Ci
  class PipelineScheduleService < BaseService
    def execute(schedule)
      # Ensure `next_run_at` is set properly before creating a pipeline.
      # Otherwise, multiple pipelines could be created in a short interval.
      schedule.schedule_next_run!

      if Feature.enabled?(:ci_pipeline_schedule_async)
        RunPipelineScheduleWorker.perform_async(schedule.id, schedule.owner&.id)
      else
        begin
          RunPipelineScheduleWorker.new.perform(schedule.id, schedule.owner&.id)
        ensure
          ##
          # This is the temporary solution for avoiding the memory bloat.
          # See more https://gitlab.com/gitlab-org/gitlab-ce/issues/61955
          GC.start if Feature.enabled?(:ci_pipeline_schedule_force_gc, default_enabled: true)
        end
      end
    end
  end
end
