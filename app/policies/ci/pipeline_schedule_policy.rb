# frozen_string_literal: true

module Ci
  class PipelineSchedulePolicy < PipelinePolicy
    alias_method :pipeline_schedule, :subject

    condition(:protected_ref) do
      if full_ref?(@subject.ref)
        is_tag = Gitlab::Git.tag_ref?(@subject.ref)
        ref_name = Gitlab::Git.ref_name(@subject.ref)
      else
        # NOTE: this block should not be removed
        # until the full ref validation is in place
        # and all old refs are updated and validated
        is_tag = @subject.project.repository.tag_exists?(@subject.ref)
        ref_name = @subject.ref
      end

      ref_protected?(@user, @subject.project, is_tag, ref_name)
    end

    condition(:owner_of_schedule) do
      pipeline_schedule.owned_by?(@user)
    end

    rule { can?(:create_pipeline) }.enable :play_pipeline_schedule

    rule { can?(:admin_pipeline) | (owner_of_schedule & can?(:update_build)) }.policy do
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

    rule { protected_ref }.policy do
      prevent :play_pipeline_schedule
      prevent :create_pipeline_schedule
      prevent :update_pipeline_schedule
    end

    private

    def full_ref?(ref)
      Gitlab::Git.tag_ref?(ref) || Gitlab::Git.branch_ref?(ref)
    end
  end
end
