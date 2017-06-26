module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    def rules
      super

      access = pipeline_schedule.project.team.max_member_access(user.id)

      if access == Gitlab::Access::DEVELOPER && pipeline_schedule.owner != user
        cannot! :update_pipeline_schedule
      end
    end
  end
end
