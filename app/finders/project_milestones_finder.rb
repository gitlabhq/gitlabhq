class ProjectMilestonesFinder
  attr_reader :projects, :params

  def initialize(projects, params)
    @projects = projects
    @params = params
  end

  def execute
    milestones = Milestone.of_projects(projects)

    Milestone.filter_by_state(milestones, params[:state])
  end
end
