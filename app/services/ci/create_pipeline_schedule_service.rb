module Ci
  class CreatePipelineScheduleService < BaseService
    def execute
      pipeline_schedule = project.pipeline_schedules.build(pipeline_schedule_params)

      if variable_keys_duplicated?
        pipeline_schedule.errors.add('variables.key', "keys are duplicated")

        return pipeline_schedule
      end

      pipeline_schedule.save
      pipeline_schedule
    end

    def update(pipeline_schedule)
      if variable_keys_duplicated?
        pipeline_schedule.errors.add('variables.key', "keys are duplicated")

        return false
      end

      pipeline_schedule.update(pipeline_schedule_params)
    end

    private

    def pipeline_schedule_params
      @pipeline_schedule_params ||= params.merge(owner: current_user)
    end

    def variable_keys_duplicated?
      attributes = pipeline_schedule_params['variables_attributes']
      return false unless attributes.is_a?(Array)

      attributes.map { |v| v['key'] }.uniq.length != attributes.length
    end
  end
end
