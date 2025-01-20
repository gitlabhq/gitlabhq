# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class PlayService < BaseService
      include Services::ReturnServiceResponses

      def execute(schedule)
        check_access!(schedule)

        return error("Failed to schedule pipeline.", :bad_request) unless project.persisted?

        # Ensure `next_run_at` is set properly before creating a pipeline.
        # Otherwise, multiple pipelines could be created in a short interval.
        schedule.schedule_next_run!
        RunPipelineScheduleWorker.perform_async(schedule.id, current_user&.id)
      end

      private

      def check_access!(schedule)
        raise Gitlab::Access::AccessDeniedError unless can?(current_user, :play_pipeline_schedule, schedule)
      end
    end
  end
end
