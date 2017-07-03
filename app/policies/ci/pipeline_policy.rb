module Ci
  class PipelinePolicy < BasePolicy
    alias_method :pipeline, :subject

    def rules
      delegate! pipeline.project

      if can?(:update_pipeline) && !can_user_update?
        cannot! :update_pipeline
      end
    end

    private

    def can_user_update?
      user_access.can_push_or_merge_to_branch?(pipeline.ref)
    end

    def user_access
      @user_access ||= ::Gitlab::UserAccess
        .new(user, project: pipeline.project)
    end
  end
end
