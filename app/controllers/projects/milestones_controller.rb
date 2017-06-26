class Projects::MilestonesController < Projects::ApplicationController
  include MilestoneActions

  before_action :check_issuables_available!
  before_action :milestone, only: [:edit, :update, :destroy, :show, :merge_requests, :participants, :labels]

  # Allow read any milestone
  before_action :authorize_read_milestone!

  # Allow admin milestone
  before_action :authorize_admin_milestone!, except: [:index, :show, :merge_requests, :participants, :labels]

  respond_to :html

  def index
    @milestones =
      case params[:state]
      when 'all' then @project.milestones
      when 'closed' then @project.milestones.closed
      else @project.milestones.active
      end

    @sort = params[:sort] || 'due_date_asc'
    @milestones = @milestones.sort(@sort)

    respond_to do |format|
      format.html do
        @project_namespace = @project.namespace.becomes(Namespace)
        @milestones = @milestones.includes(:project)
        @milestones = @milestones.page(params[:page])
      end
      format.json do
        render json: @milestones.to_json(methods: :name)
      end
    end
  end

  def new
    @milestone = @project.milestones.new
    respond_with(@milestone)
  end

  def edit
    respond_with(@milestone)
  end

  def show
  end

  def create
    @milestone = Milestones::CreateService.new(project, current_user, milestone_params).execute

    if @milestone.valid?
      redirect_to namespace_project_milestone_path(@project.namespace,
                                                   @project, @milestone)
    else
      render "new"
    end
  end

  def update
    @milestone = Milestones::UpdateService.new(project, current_user, milestone_params).execute(milestone)

    respond_to do |format|
      format.js
      format.html do
        if @milestone.valid?
          redirect_to namespace_project_milestone_path(@project.namespace,
                                                   @project, @milestone)
        else
          render :edit
        end
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_milestone, @project)

    Milestones::DestroyService.new(project, current_user).execute(milestone)

    respond_to do |format|
      format.html { redirect_to namespace_project_milestones_path, status: 302 }
      format.js { head :ok }
    end
  end

  protected

  def milestone
    @milestone ||= @project.milestones.find_by!(iid: params[:id])
  end

  def authorize_admin_milestone!
    return render_404 unless can?(current_user, :admin_milestone, @project)
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :start_date, :due_date, :state_event)
  end
end
