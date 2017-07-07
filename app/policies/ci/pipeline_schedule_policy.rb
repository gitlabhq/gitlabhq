module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    condition(:owner_of_schedule) do
      can?(:developer_access) && pipeline_schedule.owned_by?(@user)
    end

    rule { can?(:master_access) | owner_of_schedule }.policy do
      enable :update_pipeline_schedule
      enable :admin_pipeline_schedule
    end
  end
end
