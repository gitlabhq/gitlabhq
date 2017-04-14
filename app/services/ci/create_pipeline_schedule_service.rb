module Ci
  class CreatePipelineScheduleService < BaseService
    def execute
      trigger = project.triggers.create
      schedule = project.pipeline_schedules.create(pipeline_schedule_params(trigger))

      return schedule if schedule.errors.any?

      schedule.tap(&:schedule_first_run!)
    end

    private

    def pipeline_schedule_params(trigger)
      { trigger: trigger }.merge(params)
    end
  end
end
