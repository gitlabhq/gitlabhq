class GroupMilestonesFinder
  attr_reader :group, :params

  def initialize(group, params)
    @group = group
    @params = params
  end

  def execute
    GroupMilestone.filter_by_state(group.milestones, params[:state])
  end
end
