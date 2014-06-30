class Groups::MilestonesController < ApplicationController
  layout 'group'

  before_filter :authorize_group_milestone!, only: :update

  def index
    project_milestones = Milestone.where(project_id: group.projects)
    @group_milestones = Milestones::GroupService.new(project_milestones).execute
    @group_milestones = case params[:status]
                        when 'all'; @group_milestones
                        when 'closed'; status('closed')
                        else status('active')
                        end
  end

  def show
    project_milestones = Milestone.where(project_id: group.projects)
    @group_milestone = Milestones::GroupService.new(project_milestones).milestone(title)
    @issues = @group_milestone.issues
    @merge_requests = @group_milestone.merge_requests
  end

  def update
    project_milestones = Milestone.where(project_id: group.projects)
    @group_milestones = Milestones::GroupService.new(project_milestones).milestone(title)

    @group_milestones.milestones.each do |milestone|
      Milestones::UpdateService.new(milestone.project, current_user, params[:milestone]).execute(milestone)
    end

    respond_to do |format|
      format.js
      format.html do
        redirect_to group_milestones_path(group)
      end
    end
  end

  private

  def group
    @group ||= Group.find_by(path: params[:group_id])
  end

  def title
    params[:id].gsub("-", ".")
  end

  def status(state)
    @group_milestones.map{ |milestone| next if milestone.state != state; milestone }.compact
  end

  def authorize_group_milestone!
    return render_404 unless can?(current_user, :manage_group, group)
  end
end
