# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculatePerUserService < ProjectRecalculateService
    def initialize(project, user)
      @project = project
      @user = user
    end

    private

    attr_reader :user

    def apply_scopes(project_authorizations)
      super.where(user_id: user.id) # rubocop: disable CodeReuse/ActiveRecord
    end

    def effective_access_levels
      Projects::Members::EffectiveAccessLevelPerUserFinder.new(project, user).execute
    end
  end
end
