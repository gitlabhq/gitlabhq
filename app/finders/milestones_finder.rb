# Searchs for group milestones and project milestones.
#
# Parameters
# projects: array of projects or single project
# groups: array of groups or single group
# params: Search params

class MilestonesFinder
  attr_reader :projects, :groups, :params, :order

  def initialize(projects: nil, groups: nil, params: {}, order: "due_date ASC")
    @projects = Array(projects)
    @groups = Array(groups)
    @params = params
    @order = order
  end

  def execute
    conditions = []
    table = Milestone.arel_table
    project_ids = projects&.map(&:id)
    group_ids = groups&.map(&:id)

    milestones = Milestone.for_projects_and_groups(project_ids, group_ids).reorder(order)
    Milestone.filter_by_state(milestones, params[:state])
  end
end
