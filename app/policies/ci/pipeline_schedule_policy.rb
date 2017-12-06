module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    condition(:protected_ref) do
      access = ::Gitlab::UserAccess.new(@user, project: @subject.project)

      if @subject.project.repository.branch_exists?(@subject.ref)
        !access.can_update_branch?(@subject.ref)
      elsif @subject.project.repository.tag_exists?(@subject.ref)
        !access.can_create_tag?(@subject.ref)
      else
        false
      end
    end

    condition(:owner_of_schedule) do
      can?(:developer_access) && pipeline_schedule.owned_by?(@user)
    end

    rule { can?(:developer_access) }.policy do
      enable :play_pipeline_schedule
    end

    rule { can?(:master_access) | owner_of_schedule }.policy do
      enable :update_pipeline_schedule
      enable :admin_pipeline_schedule
    end

    rule { protected_ref }.prevent :play_pipeline_schedule
  end
end
