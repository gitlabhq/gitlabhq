# frozen_string_literal: true

module Preloaders
  # This class preloads the max access level (role) for the user within the given projects and
  # stores the values in requests store via the ProjectTeam class.
  class UserMaxAccessLevelInProjectsPreloader
    def initialize(projects, user)
      @projects = if projects.is_a?(Array)
                    Project.where(id: projects)
                  else
                    # Push projects base query in to a sub-select to avoid
                    # table name clashes. Performs better than aliasing.
                    Project.where(id: projects.subquery(:id))
                  end

      @user = user
    end

    def execute
      return unless @user

      project_authorizations = ProjectAuthorization.arel_table

      auths = @projects
                .select(
                  Project.default_select_columns,
                  project_authorizations[:user_id],
                  project_authorizations[:access_level]
                )
                .joins(project_auth_join)

      auths.each do |project|
        access_level = project.access_level || Gitlab::Access::NO_ACCESS
        ProjectTeam.new(project).write_member_access_for_user_id(@user.id, access_level)
      end
    end

    private

    def project_auth_join
      project_authorizations = ProjectAuthorization.arel_table
      projects = Project.arel_table

      projects
        .join(
          project_authorizations.as(project_authorizations.name),
          Arel::Nodes::OuterJoin
        )
        .on(
          project_authorizations[:project_id].eq(projects[:id])
          .and(project_authorizations[:user_id].eq(@user.id))
        )
        .join_sources
    end
  end
end
