module Ci
  class CreatePipelineScheduleService < BaseService
    def execute
      pipeline_schedule = Ci::PipelineSchedule.new(
        description: params[:description],
        ref: params[:ref],
        cron: params[:cron],
        cron_timezone: params[:cron_timezone],
        project: project,
        owner: current_user
      )

      Ci::PipelineSchedule.transaction do
        pipeline_schedule.save!

        if params[:variables_attributes].is_a?(Array)
          pipeline_schedule.variables.create!(params[:variables_attributes])
        end
      end

      rescue Exception => e
        pipeline_schedule.errors[:base] << "Failed to persist the pipeline schedule: #{e}"
      ensure
        return pipeline_schedule
    end
  end
end
