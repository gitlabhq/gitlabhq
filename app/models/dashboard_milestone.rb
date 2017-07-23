class DashboardMilestone < GlobalMilestone
  def issues_finder_params
    { authorized_only: true }
  end

  def is_dashboard_milestone?
    true
  end
end
