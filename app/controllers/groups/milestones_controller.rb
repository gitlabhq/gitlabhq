class Groups::MilestonesController < ApplicationController
  layout 'group'

  before_filter :authorize_group_milestone!, only: :update

  def index
    project_milestones = case params[:status]
                         when 'all'; status
                         when 'closed'; status('closed')
                         else status('active')
                         end
    @group_milestones = Milestones::GroupService.new(project_milestones).execute
    @group_milestones = Kaminari.paginate_array(@group_milestones).page(params[:page]).per(30)
  end

  def show
    project_milestones = Milestone.where(project_id: group.projects).order("due_date ASC")
    @group_milestone = Milestones::GroupService.new(project_milestones).milestone(title)
  end

  def update
    project_milestones = Milestone.where(project_id: group.projects).order("due_date ASC")
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
    params[:title]
  end

  def status(state = nil)
    conditions = { project_id: group.projects }
    conditions.reverse_merge!(state: state) if state
    Milestone.where(conditions).order("title ASC")
  end

  def authorize_group_milestone!
    return render_404 unless can?(current_user, :manage_group, group)
  end
end
