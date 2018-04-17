module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    condition(:protected_ref) do
      ref_protected?(@user, @subject.project, @subject.project.repository.tag_exists?(@subject.ref), @subject.ref)
    end

    condition(:owner_of_schedule) do
      pipeline_schedule.owned_by?(@user)
    end

    rule { can?(:create_pipeline) }.enable :play_pipeline_schedule

    rule { can?(:admin_pipeline) | (can?(:update_build) & owner_of_schedule) }.policy do
      enable :update_pipeline_schedule
      enable :admin_pipeline_schedule
    end

    rule { can?(:admin_pipeline_schedule) & ~owner_of_schedule }.policy do
      enable :take_ownership_pipeline_schedule
    end

    rule { protected_ref }.prevent :play_pipeline_schedule
  end
end
