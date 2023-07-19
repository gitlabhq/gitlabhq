# frozen_string_literal: true

module Ci
  # This class is deprecated and will be removed with the FF ci_refactoring_pipeline_schedule_create_service
  class CreatePipelineScheduleService < BaseService
    def execute
      project.pipeline_schedules.create(pipeline_schedule_params)
    end

    private

    def pipeline_schedule_params
      params.merge(owner: current_user)
    end
  end
end
