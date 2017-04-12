module Ci
  class BuildPolicy < CommitStatusPolicy
    def rules
      super

      # If we can't read build we should also not have that
      # ability when looking at this in context of commit_status
      %w[read create update admin].each do |rule|
        cannot! :"#{rule}_commit_status" unless can? :"#{rule}_build"
      end

      can! :play_build if can_play_action?
    end

    private

    alias_method :build, :subject

    def can_play_action?
      return false unless build.action?

      ::Gitlab::UserAccess
        .new(user, project: build.project)
        .can_push_to_branch?(build.ref)
    end
  end
end
