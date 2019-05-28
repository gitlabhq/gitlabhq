# frozen_string_literal: true

module DashboardHelper
  def assigned_issues_dashboard_path
    issues_dashboard_path(assignee_username: current_user.username)
  end

  def assigned_mrs_dashboard_path
    merge_requests_dashboard_path(assignee_username: current_user.username)
  end

  def dashboard_nav_links
    @dashboard_nav_links ||= get_dashboard_nav_links
  end

  def dashboard_nav_link?(link)
    dashboard_nav_links.include?(link)
  end

  def any_dashboard_nav_link?(links)
    links.any? { |link| dashboard_nav_link?(link) }
  end

  def has_start_trial?
    false
  end

  private

  def get_dashboard_nav_links
    links = [:projects, :groups, :snippets]

    if can?(current_user, :read_cross_project)
      links += [:activity, :milestones]
    end

    links
  end
end
