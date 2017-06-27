module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    def rules
      super

      if owned_by_developer? && pipeline_schedule.owner != user
        cannot! :update_pipeline_schedule
      end
    end

    private

    def owned_by_developer?
      pipeline_schedule.project.team.developer?(user)
    end
  end
end
