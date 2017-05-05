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

      if can?(:update_build) && protected_action?
        cannot! :update_build
      end
    end

    private

    def protected_action?
      return false unless build.action?

      !::Gitlab::UserAccess
        .new(user, project: build.project)
        .can_push_to_branch?(build.ref)
    end
  end
end
