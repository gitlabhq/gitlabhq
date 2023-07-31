# frozen_string_literal: true

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
      enable :admin_pipeline_schedule
      enable :read_pipeline_schedule_variables
    end

    rule { admin | (owner_of_schedule & can?(:update_build)) }.policy do
      enable :update_pipeline_schedule
    end

    # `take_ownership_pipeline_schedule` is deprecated, and should not be used. It can be removed in 17.0
    # once the deprecated field `take_ownership_pipeline_schedule` is removed from the GraphQL type
    # `PermissionTypes::Ci::PipelineSchedules`.
    # Use `admin_pipeline_schedule` to decide if a user has the ability to take ownership of a pipeline schedule.
    rule { can?(:admin_pipeline_schedule) & ~owner_of_schedule }.policy do
      enable :take_ownership_pipeline_schedule
    end

    rule { protected_ref }.prevent :play_pipeline_schedule
  end
end
