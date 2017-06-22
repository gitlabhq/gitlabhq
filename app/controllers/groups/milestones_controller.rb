class Groups::MilestonesController < Groups::ApplicationController
  include MilestoneActions

  before_action :group_projects
  before_action :milestone, only: [:show, :update, :merge_requests, :participants, :labels]
  before_action :authorize_admin_milestones!, only: [:new, :create, :update]

  def index
    respond_to do |format|
      format.html do
        @milestone_states = GlobalMilestone.states_count(@projects, group)
        @milestones = Kaminari.paginate_array(milestones).page(params[:page])
      end
      format.json do
        render json: milestones.map { |m| m.for_display.slice(:title, :name) }
      end
    end
  end

  def new
    @milestone = GroupMilestone.new
  end

  def create
    title = milestone_params[:title]
    @milestone = Milestones::CreateService.new(group, current_user, milestone_params).execute

    if @milestone.save
      redirect_to milestone_path(title)
    else
      render_new_with_error
    end
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

  def render_new_with_error(empty_project_ids)
    @milestone = Milestone.new(milestone_params)
    @milestone.errors.add(:base, "Please select at least one project.") if empty_project_ids
    render :new
  end

  def authorize_admin_milestones!
    return render_404 unless can?(current_user, :admin_milestones, group)
  end

  def milestone_params
    params.require(:group_milestone).permit(:title, :description, :start_date, :due_date, :state_event)
  end

  def milestone_path(title)
    group_milestone_path(@group, title.to_slug.to_s, title: title)
  end

  def milestones
    @group_milestones = GroupMilestone.all
    @project_milestones = Milestone.where(project_id: group.projects.pluck(:id))

    @group_milestones + @project_milestones
    #@milestones = GroupMilestone.build_collection(@group, @projects, params)
  end

  def milestone
    @milestone =
      @group.milestones.find_by_title(params[:title]) ||
      GroupMilestone.build(@group, @projects, params[:title])

    render_404 unless @milestone
  end
end
