# frozen_string_literal: true

module Preloaders
  # This class preloads the max access level (role) for the users within the given projects and
  # stores the values in requests store via the ProjectTeam class.
  class UsersMaxAccessLevelInProjectsPreloader
    def initialize(projects:, users:)
      @projects = projects
      @users = users
    end

    def execute
      return unless @projects.present? && @users.present?

      preload_users_namespace_bans(@users)

      access_levels.each do |(project_id, user_id), access_level|
        project = projects_by_id[project_id]

        project.team.write_member_access_for_user_id(user_id, access_level)
      end
    end

    private

    def access_levels
      ProjectAuthorization
        .where(project_id: project_ids, user_id: user_ids)
        .group(:project_id, :user_id)
        .maximum(:access_level)
    end

    # Use reselect to override the existing select to prevent
    # the error `subquery has too many columns`
    # NotificationsController passes in an Array so we need to check the type
    def project_ids
      @projects.is_a?(ActiveRecord::Relation) ? @projects.reselect(:id) : @projects
    end

    def user_ids
      @users.is_a?(ActiveRecord::Relation) ? @users.reselect(:id) : @users
    end

    def projects_by_id
      @projects_by_id ||= @projects.index_by(&:id)
    end

    def preload_users_namespace_bans(_users)
      # overridden in EE
    end
  end
end

# Preloaders::UsersMaxAccessLevelInProjectsPreloader.prepend_mod
