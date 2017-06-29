module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    condition(:protected_action) do
      owned_by_developer? && owned_by_another?
    end

    rule { protected_action }.prevent :update_pipeline_schedule

    private

    def owned_by_developer?
      return false unless @user

      pipeline_schedule.project.team.developer?(@user)
    end

    def owned_by_another?
      return false unless @user

      !pipeline_schedule.owned_by?(@user)
    end
  end
end
