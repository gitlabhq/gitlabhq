class DashboardMilestone < GlobalMilestone
  def issues_finder_params
    super.merge({ authorized_only: true })
  end
end
