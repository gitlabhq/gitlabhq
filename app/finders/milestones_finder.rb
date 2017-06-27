class MilestonesFinder
  attr_reader :projects, :group, :params

  def initialize(projects = nil, group = nil, params = {})
    @projects = projects
    @group = group
    @params = params
  end

  def execute
    table = Milestone.arel_table
    project_ids = projects&.map(&:id)
    group_id = group&.id

    milestones =
      Milestone.where(table[:project_id].in(project_ids)
        .or(table[:group_id].eq(group_id))
      )

    Milestone.filter_by_state(milestones, params[:state])
  end
end
