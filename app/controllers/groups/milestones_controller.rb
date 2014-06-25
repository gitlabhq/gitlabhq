class Groups::MilestonesController < ApplicationController
  layout 'group'

  def index
    @group = Group.find_by(path: params[:group_id])
    project_ids = @group.projects
    project_milestones = Milestone.where(project_id: project_ids)
    @milestones = project_milestones
    @group_milestones = Milestones::GroupService.new(@group, current_user, project_milestones)
  end

end
