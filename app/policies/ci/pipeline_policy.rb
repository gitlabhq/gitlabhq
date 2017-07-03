module Ci
  class PipelinePolicy < BasePolicy
    delegate { pipeline.project }

    condition(:user_cannot_update) do
      !::Gitlab::UserAccess
        .new(@user, project: @subject.project)
        .can_push_or_merge_to_branch?(@subject.ref)
    end

    rule { user_cannot_update }.prevent :update_pipeline
  end
end
