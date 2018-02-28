class DashboardMilestone < GlobalMilestone
  def issues_finder_params
    { authorized_only: true }
  end

  def dashboard_milestone?
    true
  end
end
