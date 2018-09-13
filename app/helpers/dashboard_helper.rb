module DashboardHelper
  def assigned_issues_dashboard_path
    issues_dashboard_path(assignee_id: current_user.id)
  end

  def assigned_mrs_dashboard_path
    merge_requests_dashboard_path(assignee_id: current_user.id)
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

  def controller_action_to_child_dashboards(controller = controller_name, action = action_name)
    case "#{controller}##{action}"
    when 'projects#index', 'root#index', 'projects#starred', 'projects#trending'
      %w(projects, 'stars)
    when 'dashboard#activity'
      %w(starred_project_activity, 'project_activity)
    when 'groups#index'
      %w(groups)
    when 'todos#index'
      %w(todos)
    when 'dashboard#issues'
      %w(issues)
    when 'dashboard#merge_requests'
      %w(merge_requests)
    else
      []
    end
  end

  def is_default_dashboard?(user = current_user)
    controller_action_to_child_dashboards.any? {|dashboard| dashboard == user.dashboard }
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
