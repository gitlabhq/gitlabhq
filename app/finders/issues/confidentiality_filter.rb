# frozen_string_literal: true

module Issues
  class ConfidentialityFilter < Issuables::BaseFilter
    CONFIDENTIAL_ACCESS_LEVEL = Gitlab::Access::PLANNER

    def initialize(current_user:, parent:, assignee_filter:, related_groups: nil, **kwargs)
      @current_user = current_user
      @parent = parent
      @assignee_filter = assignee_filter
      @related_groups = related_groups

      super(**kwargs)
    end

    def filter(issues)
      issues = issues.confidential_only if params[:confidential]

      # We do not need to do the confidentiality check if we know that only public issues will be returned
      return issues.public_only if @current_user.blank? || params[:confidential] == false

      return issues if user_can_see_all_confidential_issues?

      issues.public_only.or(
        issues.confidential_only.merge(
          issues.authored(@current_user)
            .or(issues.assigned_to(@current_user))
            .or(access_to_parent_exists(issues))
        )
      ).allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422045')
    end

    private

    def user_can_see_all_confidential_issues?
      Ability.allowed?(@current_user, :read_all_resources) ||
        Ability.allowed?(@current_user, :read_confidential_issues, @parent) ||
        # If already filtering by assignee we can skip confidentiality checks since a user
        # can always see confidential issues assigned to them. This is just an
        # optimization since a very common use case of this Finder is to load the
        # count of issues assigned to the user for the header bar.
        @assignee_filter.includes_user?(@current_user)
    end

    def access_to_parent_exists(issues)
      access_to_project_level_issue_exists = issues.where_exists(
        @current_user.authorizations_for_projects(
          min_access_level: CONFIDENTIAL_ACCESS_LEVEL,
          related_project_column: 'issues.project_id'
        )
      )

      return access_to_project_level_issue_exists if @related_groups.nil?

      access_to_project_level_issue_exists.project_level.or(
        issues.group_level.in_namespaces(
          Group.id_in(
            Group.groups_user_can(@related_groups, @current_user, :read_confidential_issues, same_root: true)
          )
        )
      )
    end
  end
end
