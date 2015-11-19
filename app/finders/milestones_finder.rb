class MilestonesFinder
  def execute(projects, params)
    milestones = Milestone.of_projects(projects)
    milestones = milestones.order("due_date ASC")

    case params[:state]
    when 'closed' then milestones.closed
    when 'all' then milestones
    else milestones.active
    end
  end
end
