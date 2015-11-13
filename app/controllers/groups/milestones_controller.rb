class Groups::MilestonesController < Groups::ApplicationController
  before_action :authorize_group_milestone!, only: :update
  before_action :group

  def index
    project_milestones =
      case params[:state]
      when 'all'; state
      when 'closed'; state('closed')
      else state('active')
      end

    @group_milestones = Milestones::GroupService.new(project_milestones).execute
    @group_milestones = Kaminari.paginate_array(@group_milestones).page(params[:page]).per(PER_PAGE)
  end

  def new
    @group_milestone = OpenStruct.new(title: nil, description: nil)
  end

  def create
    project_ids = params[:milestone][:project_ids]
    title = milestone_params[:title]

    @group.projects.where(id: project_ids).each do |project|
      Milestones::CreateService.new(project, current_user, milestone_params).execute
    end

    redirect_to group_milestone_path(@group, title.parameterize, title: title)
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

  def state(state = nil)
    conditions = { project_id: group.projects }
    conditions.reverse_merge!(state: state) if state
    Milestone.where(conditions).order("title ASC")
  end

  def authorize_group_milestone!
    return render_404 unless can?(current_user, :admin_group, group)
  end

  def milestone_params
    params.require(:milestone).permit(
      :title,
      :description,
      :due_date
    )
  end
end
