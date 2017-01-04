class MilestonesFinder
  def execute(projects, params)
    milestones = Milestone.of_projects(projects)
    milestones = by_state(milestones)
    milestones = by_iid(milestones, params[:iid])
    sort(milestones)
  end

  def sort(milestones)
    milestones.reorder(due_date: :asc)
  end

  def by_state(milestones)
    case params[:state]
    when 'closed'
       milestones.closed
    when 'all'
       milestones
    else
      milestones.active
    end
  end

  def by_iid(milestones, iid)
    params[:iid].present? ? milestones.where(iid: iid) : milestones
  end
end
