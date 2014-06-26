class Groups::MilestonesController < ApplicationController
  layout 'group'

  def index
    @group = Group.find_by(path: params[:group_id])
    project_ids = @group.projects
    project_milestones = Milestone.where(project_id: project_ids)
    @group_milestones = Milestones::GroupService.new(project_milestones).execute
    @group_milestones = case params[:status]
                        when 'all'; @group_milestones
                        when 'closed'; status('closed')
                        else status('active')
                        end
  end

  private

  def status(state)
    @group_milestones.map{ |milestone| next if milestone.state != state; milestone }.compact
  end
end
