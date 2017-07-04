module Ci
  class UpdatePipelineScheduleService < BaseService
    def execute(pipeline_schedule)
      if Ci::NestedUniquenessValidator.duplicated?(pipeline_schedule_params['variables_attributes'], 'key')
        pipeline_schedule.errors.add('variables.key', "keys are duplicated")

        return false
      end

      pipeline_schedule.update(pipeline_schedule_params)
    end

    private

    def pipeline_schedule_params
      @pipeline_schedule_params ||= params.merge(owner: current_user)
    end
  end
end
