# frozen_string_literal: true

module Ci
  class PipelineScheduleService < BaseService
    def execute(schedule)
      # Ensure `next_run_at` is set properly before creating a pipeline.
      # Otherwise, multiple pipelines could be created in a short interval.
      schedule.schedule_next_run!
      RunPipelineScheduleWorker.perform_async(schedule.id, schedule.owner&.id)
    end
  end
end
