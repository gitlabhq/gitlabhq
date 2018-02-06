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
    @milestone = Milestones::CreateService.new(group, current_user, milestone_params).execute

    if @milestone.persisted?
      redirect_to milestone_path
    else
      render "new"
    end
  end

  def show
  end

  def edit
    render_404 if @milestone.legacy_group_milestone?
  end

  def update
    # Keep this compatible with legacy group milestones where we have to update
    # all projects milestones states at once.
    if @milestone.legacy_group_milestone?
      update_params = milestone_params.select { |key| key == "state_event" }
      milestones = @milestone.milestones
    else
      update_params = milestone_params
      milestones = [@milestone]
    end

    milestones.each do |milestone|
      Milestones::UpdateService.new(milestone.parent, current_user, update_params).execute(milestone)
    end

    redirect_to milestone_path
  end

  private

  def authorize_admin_milestones!
    return render_404 unless can?(current_user, :admin_milestones, group)
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :start_date, :due_date, :state_event)
  end

  def milestone_path
    if @milestone.legacy_group_milestone?
      group_milestone_path(group, @milestone.safe_title, title: @milestone.title)
    else
      group_milestone_path(group, @milestone.iid)
    end
  end

  def milestones
    milestones = MilestonesFinder.new(search_params).execute
    legacy_milestones = GroupMilestone.build_collection(group, group_projects, params)

    @sort = params[:sort] || 'due_date_asc'
    MilestoneArray.sort(milestones + legacy_milestones, @sort)
  end

  def milestone
    @milestone =
      if params[:title]
        GroupMilestone.build(group, group_projects, params[:title])
      else
        group.milestones.find_by_iid(params[:id])
      end

    render_404 unless @milestone
  end

  def search_params
    params.permit(:state).merge(group_ids: group.id)
  end
end
