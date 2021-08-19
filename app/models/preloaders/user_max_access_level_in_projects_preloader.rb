# frozen_string_literal: true

module Preloaders
  # This class preloads the max access level (role) for the user within the given projects and
  # stores the values in requests store via the ProjectTeam class.
  class UserMaxAccessLevelInProjectsPreloader
    def initialize(projects, user)
      @projects = projects
      @user = user
    end

    def execute
      # Use reselect to override the existing select to prevent
      # the error `subquery has too many columns`
      # NotificationsController passes in an Array so we need to check the type
      project_ids = @projects.is_a?(ActiveRecord::Relation) ? @projects.reselect(:id) : @projects
      access_levels = @user
        .project_authorizations
        .where(project_id: project_ids)
        .group(:project_id)
        .maximum(:access_level)

      @projects.each do |project|
        access_level = access_levels[project.id] || Gitlab::Access::NO_ACCESS
        ProjectTeam.new(project).write_member_access_for_user_id(@user.id, access_level)
      end
    end
  end
end
