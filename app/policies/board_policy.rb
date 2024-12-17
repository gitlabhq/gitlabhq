# frozen_string_literal: true

class BoardPolicy < BasePolicy
  include FindGroupProjects

  delegate { @subject.resource_parent }

  condition(:is_group_board) { @subject.group_board? }
  condition(:is_project_board) { @subject.project_board? }

  rule { is_project_board & can?(:read_project) }.enable :read_parent

  rule { is_group_board & can?(:read_group) }.policy do
    enable :read_parent
    enable :read_milestone
    enable :read_issue
  end

  condition(:planner_of_group_projects) do
    next unless @user

    group_projects_for(user: @user, group: @subject.resource_parent)
      .visible_to_user_and_access_level(@user, ::Gitlab::Access::PLANNER)
      .exists?
  end

  rule { admin }.policy do
    enable :create_non_backlog_issues
  end

  rule { is_group_board & planner_of_group_projects }.policy do
    enable :create_non_backlog_issues
  end

  rule { is_project_board & can?(:admin_issue) }.policy do
    enable :create_non_backlog_issues
  end
end
