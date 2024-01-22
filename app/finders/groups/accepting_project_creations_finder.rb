# frozen_string_literal: true

module Groups
  class AcceptingProjectCreationsFinder
    def initialize(current_user)
      @current_user = current_user
    end

    def execute
      groups_accepting_project_creations =
        [
          current_user
            .manageable_groups(include_groups_with_developer_maintainer_access: true)
            .project_creation_allowed(current_user),
          owner_maintainer_groups_originating_from_group_shares
            .project_creation_allowed(current_user),
          *developer_groups_originating_from_group_shares
        ]

      # We move the UNION query into a materialized CTE to improve query performance during text search.
      union_query = ::Group.from_union(groups_accepting_project_creations)
      cte = Gitlab::SQL::CTE.new(:my_union_cte, union_query)

      Group.with(cte.to_arel).from(cte.alias_to(Group.arel_table)) # rubocop: disable CodeReuse/ActiveRecord
    end

    private

    attr_reader :current_user

    def owner_maintainer_groups_originating_from_group_shares
      GroupGroupLink
        .with_owner_or_maintainer_access
        .groups_accessible_via(
          groups_that_user_has_owner_or_maintainer_access_via_direct_membership
          .select(:id)
        )
    end

    def groups_that_user_has_owner_or_maintainer_access_via_direct_membership
      current_user.owned_or_maintainers_groups
    end

    def developer_groups_originating_from_group_shares
      # Example:
      #
      # Group A -----shared to---> Group B
      #

      # Now, there are 2 ways a user in Group A can get "Developer" access to Group B (and it's subgroups)
      [
        # 1. User has Developer or above access in Group A,
        # but the group_group_link has MAX access level set to Developer
        GroupGroupLink
          .with_developer_access
          .groups_accessible_via(
            groups_that_user_has_developer_access_and_above_via_direct_membership
            .select(:id)
          ).with_project_creation_levels(project_creations_levels_allowing_developers_to_create_projects),

        # 2. User has exactly Developer access in Group A,
        # but the group_group_link has MAX access level set to Developer or above.
        GroupGroupLink
          .with_developer_maintainer_owner_access
          .groups_accessible_via(
            groups_that_user_has_developer_access_via_direct_membership
            .select(:id)
          ).with_project_creation_levels(project_creations_levels_allowing_developers_to_create_projects)
      ]

      # Lastly, we should make sure that such groups indeed allow Developers to create projects in them,
      # based on the value of `groups.project_creation_level`,
      # which is why we use the scope .with_project_creation_levels on each set.
    end

    def groups_that_user_has_developer_access_and_above_via_direct_membership
      current_user.developer_maintainer_owned_groups
    end

    def groups_that_user_has_developer_access_via_direct_membership
      current_user.developer_groups
    end

    def project_creations_levels_allowing_developers_to_create_projects
      project_creation_levels = [::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS]

      # When the value of application_settings.default_project_creation is set to `DEVELOPER_MAINTAINER_PROJECT_ACCESS`,
      # it means that a `nil` value for `groups.project_creation_level` is telling us:
      # such groups also have `project_creation_level` implicitly set to `DEVELOPER_MAINTAINER_PROJECT_ACCESS`.
      # ie, `nil` is a placeholder value for inheriting the value from the ApplicationSetting.
      # So we will include `nil` in the list,
      # when the application_setting's value is `DEVELOPER_MAINTAINER_PROJECT_ACCESS`

      if ::Gitlab::CurrentSettings.default_project_creation == ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
        project_creation_levels << nil
      end

      project_creation_levels
    end
  end
end
