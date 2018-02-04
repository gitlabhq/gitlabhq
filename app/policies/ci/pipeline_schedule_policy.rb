module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    condition(:protected_ref) do
      ref_protected?(@user, @subject.project, @subject.project.repository.tag_exists?(@subject.ref), @subject.ref)
    end

    condition(:owner_of_schedule) do
      can?(:developer_access) && pipeline_schedule.owned_by?(@user)
    end

    condition(:non_owner_of_schedule) do
      !pipeline_schedule.owned_by?(@user)
    end

    rule { can?(:developer_access) }.policy do
      enable :play_pipeline_schedule
    end

    rule { can?(:master_access) | owner_of_schedule }.policy do
      enable :update_pipeline_schedule
      enable :admin_pipeline_schedule
    end

    rule { can?(:master_access) & non_owner_of_schedule }.policy do
      enable :take_ownership_pipeline_schedule
    end

    rule { protected_ref }.prevent :play_pipeline_schedule
  end
end
