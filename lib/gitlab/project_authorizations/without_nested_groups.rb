module Gitlab
  module ProjectAuthorizations
    # Calculating new project authorizations when not supporting nested groups.
    class WithoutNestedGroups
      attr_reader :user

      # user - The User object for which to calculate the authorizations.
      def initialize(user)
        @user = user
      end

      def calculate
        relations = [
          # Projects the user is a direct member of
          user.projects.select_for_project_authorization,

          # Personal projects
          user.personal_projects.select_as_maintainer_for_project_authorization,

          # Projects of groups the user is a member of
          user.groups_projects.select_for_project_authorization,

          # Projects shared with groups the user is a member of
          user.groups.joins(:shared_projects).select_for_project_authorization
        ]

        ProjectAuthorization
          .unscoped
          .select_from_union(relations)
      end
    end
  end
end
