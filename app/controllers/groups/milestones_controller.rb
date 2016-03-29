class Groups::MilestonesController < Groups::ApplicationController
  include GlobalMilestones

  before_action :group_projects
  before_action :milestone, only: [:show, :update]
  before_action :authorize_admin_milestones!, only: [:new, :create, :update]

  def index
    respond_to do |format|
      format.html do
        @milestones = Kaminari.paginate_array(milestones).page(params[:page])
      end
    end
  end

  def new
    @milestone = Milestone.new
  end

  def create
    project_ids = params[:milestone][:project_ids]
    title = milestone_params[:title]

    @projects.where(id: project_ids).each do |project|
      Milestones::CreateService.new(project, current_user, milestone_params).execute
    end

    redirect_to milestone_path(title)
  end

  def show
  end

  def update
    @milestone.milestones.each do |milestone|
      Milestones::UpdateService.new(milestone.project, current_user, milestone_params).execute(milestone)
    end

    redirect_back_or_default(default: milestone_path(@milestone.title))
  end

  private

  def authorize_admin_milestones!
    return render_404 unless can?(current_user, :admin_milestones, group)
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :due_date, :state_event)
  end

  def milestone_path(title)
    group_milestone_path(@group, title.to_slug.to_s, title: title)
  end
end
