class Groups::MilestonesController < Groups::ApplicationController
  include MilestoneActions

  before_action :group_projects
  before_action :milestone, only: [:show, :update, :merge_requests, :participants, :labels]
  before_action :authorize_admin_milestones!, only: [:new, :create, :update]

  def index
    respond_to do |format|
      format.html do
        @milestone_states = GlobalMilestone.states_count(@projects)
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
    # Use a service to create the milestone here
    title = milestone_params[:title]
    @milestone = GroupMilestone.new(milestone_params)

    if @milestone.save
      redirect_to milestone_path(title)
    else
      render_new_with_error(project_ids.empty?)
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

  # def create_milestones(project_ids)
  #   return false unless project_ids.present?

  #   ActiveRecord::Base.transaction do
  #     @projects.where(id: project_ids).each do |project|
  #       Milestones::CreateService.new(project, current_user, milestone_params).execute
  #     end
  #   end

  #   true
  # rescue ActiveRecord::ActiveRecordError => e
  #   flash.now[:alert] = "An error occurred while creating the milestone: #{e.message}"
  #   false
  # end

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
    @milestones = GroupMilestone.all
  end

  def milestone
    # Use a finder here
    @milestone = GroupMilestone.find(params[:id])
    render_404 unless @milestone
  end
end
