# Searchs for group milestones and project milestones.
#
# Parameters
# projects: array of projects or single project
# groups: array of groups or single group
# params: Search params

class MilestonesFinder
  attr_reader :projects, :groups, :params

  def initialize(projects: nil, groups: nil, params: {})
    @projects = Array(projects)
    @groups = Array(groups)
    @params = params
  end

  def execute
    conditions = []
    table = Milestone.arel_table
    project_ids = projects&.map(&:id)
    group_ids = groups&.map(&:id)

    conditions << table[:group_id].in(group_ids) if group_ids
    conditions << table[:project_id].in(project_ids) if project_ids

    milestones = Milestone.where(conditions.reduce(:or)).reorder("due_date ASC")
    Milestone.filter_by_state(milestones, params[:state])
  end
end
