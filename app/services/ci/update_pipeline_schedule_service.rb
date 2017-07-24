module Ci
  class UpdatePipelineScheduleService < BaseService
    def execute(pipeline_schedule)
      Ci::PipelineSchedule.transaction do
        pipeline_schedule.update!(params.delete(:variables_attributes))

        if params[:variables_attributes].is_a?(Array)
          pipeline_schedule.variables.update!(params[:variables_attributes])
        end
      end

      rescue Exception => e
        pipeline_schedule.errors[:base] << "Failed to update the pipeline schedule: #{e}"
      ensure
        return pipeline_schedule
    end
  end
end
