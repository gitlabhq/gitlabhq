module Ci
  class BuildPolicy < CommitStatusPolicy
    alias_method :build, :subject

    def rules
      super

      # If we can't read build we should also not have that
      # ability when looking at this in context of commit_status
      %w[read create update admin].each do |rule|
        cannot! :"#{rule}_commit_status" unless can? :"#{rule}_build"
      end

      if can?(:update_build) && !can_user_update?
        cannot! :update_build
      end
    end

    private

    def can_user_update?
      user_access.can_push_or_merge_to_branch?(build.ref)
    end

    def user_access
      @user_access ||= ::Gitlab::UserAccess
        .new(user, project: build.project)
    end
  end
end
