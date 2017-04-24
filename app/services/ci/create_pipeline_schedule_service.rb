module Ci
  class CreatePipelineScheduleService < BaseService
    def execute
      trigger = project.triggers.create(owner: current_user)
      project.pipeline_schedules.create(pipeline_schedule_params(trigger))
    end

    private

    def pipeline_schedule_params(trigger)
      params.merge(trigger: trigger)
    end
  end
end
