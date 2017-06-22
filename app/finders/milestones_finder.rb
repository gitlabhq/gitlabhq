class MilestonesFinder
  def execute(projects, group = nil, params)
    milestones = group ? group.milestones : Milestone.of_projects(projects)

    filter_by_state(milestones, params[:state])
  end

  def filter_by_state(milestones, state)
    case state
    when 'closed' then milestones.closed
    when 'all' then milestones
    else milestones.active
    end
  end
end
