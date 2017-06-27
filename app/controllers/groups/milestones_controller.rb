class Groups::MilestonesController < Groups::ApplicationController
  include MilestoneActions

  before_action :group_projects
  before_action :milestone, only: [:edit, :show, :update, :merge_requests, :participants, :labels]
  before_action :authorize_admin_milestones!, only: [:edit, :new, :create, :update]

  def index
    respond_to do |format|
      format.html do
        @milestone_states = GlobalMilestone.states_count(group_projects, group)
        @milestones = Kaminari.paginate_array(milestones).page(params[:page])
      end
      format.json do
        render json: milestones.map { |m| m.for_display.slice(:title, :name) }
      end
    end
  end

  def new
    @milestone = Milestone.new
  end

  def create
    title = milestone_params[:title]
    @milestone = Milestones::CreateService.new(group, current_user, milestone_params).execute

    if @milestone.persisted?
      redirect_to milestone_path(title)
    else
      render "new"
    end
  end

  def show
  end

  def edit
    render_404 if @milestone.is_legacy_group_milestone?
  end

  def update
    milestones = @milestone.milestones if @milestone.is_legacy_group_milestone?
    # Keep this compatible with legacy group milestones where we have to update
    # all projects milestones at once.
    milestones ||= Array(@milestone)

    milestones.each do |milestone|
      Milestones::UpdateService.new(milestone.parent, current_user, milestone_params).execute(milestone)
    end

    redirect_to milestone_path(@milestone.title)
  end

  private

  def authorize_admin_milestones!
    return render_404 unless can?(current_user, :admin_milestones, group)
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :start_date, :due_date, :state_event)
  end

  def milestone_path(title)
    group_milestone_path(group, title.to_slug.to_s, title: title)
  end

  def milestones
    milestones = MilestonesFinder.new(groups: group, params: params).execute
    legacy_milestones = GroupMilestone.build_collection(group, group_projects, params) || []

    milestones + legacy_milestones
  end

  def milestone
    @milestone =
      group.milestones.find_by_title(params[:title]) || GroupMilestone.build(group, group_projects, params[:title])

    render_404 unless @milestone
  end
end
