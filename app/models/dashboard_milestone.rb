# frozen_string_literal: true

class DashboardMilestone < GlobalMilestone
  attr_reader :project_name

  def initialize(milestone)
    super

    @project_name = milestone.project.full_name
  end

  def project_milestone?
    true
  end
end
