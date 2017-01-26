class MilestonesFinder

  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def execute(projects)
    milestones = Milestone.of_projects(projects)
    milestones = by_state(milestones)
    milestones = by_iid(milestones, params[:iid])
    milestones = by_search(milestones, params[:search])

    sort(milestones)
  end

  def sort(milestones)
    if params[:sort_by].present? && params[:sort_direction].present?
      milestones.reorder(params[:sort_by] => params[:sort_direction])
    else
      milestones.reorder(due_date: :asc)
    end
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

  def by_iid(milestones)
    params[:iid].present? ? milestones.where(iid: params[:iid]) : milestones
  end

  def by_search(milestones, search)
    milestones.search(search) if search
  end
end
