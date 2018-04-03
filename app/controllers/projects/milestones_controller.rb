class Projects::MilestonesController < Projects::ApplicationController
  include MilestoneActions

  before_action :check_issuables_available!
  before_action :milestone, only: [:edit, :update, :destroy, :show, :merge_requests, :participants, :labels, :promote]

  # Allow read any milestone
  before_action :authorize_read_milestone!

  # Allow admin milestone
  before_action :authorize_admin_milestone!, except: [:index, :show, :merge_requests, :participants, :labels, :promote]

  respond_to :html

  def index
    @sort = params[:sort] || 'due_date_asc'
    @milestones = milestones.sort(@sort)

    respond_to do |format|
      format.html do
        @project_namespace = @project.namespace.becomes(Namespace)
        # We need to show group milestones in the JSON response
        # so that people can filter by and assign group milestones,
        # but we don't need to show them on the project milestones page itself.
        @milestones = @milestones.for_projects
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
    @project_namespace = @project.namespace.becomes(Namespace)

    respond_to do |format|
      format.html
    end
  end

  def create
    @milestone = Milestones::CreateService.new(project, current_user, milestone_params).execute

    if @milestone.valid?
      redirect_to project_milestone_path(@project, @milestone)
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
          redirect_to project_milestone_path(@project, @milestone)
        else
          render :edit
        end
      end
    end
  end

  def promote
    promoted_milestone = Milestones::PromoteService.new(project, current_user).execute(milestone)

    flash[:notice] = "#{milestone.title} promoted to <a href=\"#{group_milestone_path(project.group, promoted_milestone.iid)}\">group milestone</a>.".html_safe
    respond_to do |format|
      format.html do
        redirect_to project_milestones_path(project)
      end
      format.json do
        render json: { url: project_milestones_path(project) }
      end
    end
  rescue Milestones::PromoteService::PromoteMilestoneError => error
    redirect_to milestone, alert: error.message
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_milestone, @project)

    Milestones::DestroyService.new(project, current_user).execute(milestone)

    respond_to do |format|
      format.html { redirect_to namespace_project_milestones_path, status: 303 }
      format.js { head :ok }
    end
  end

  protected

  def milestones
    @milestones ||= begin
      MilestonesFinder.new(search_params).execute
    end
  end

  def milestone
    @milestone ||= @project.milestones.find_by!(iid: params[:id])
  end

  def authorize_admin_milestone!
    return render_404 unless can?(current_user, :admin_milestone, @project)
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :start_date, :due_date, :state_event)
  end

  def search_params
    if @project.group && can?(current_user, :read_group, @project.group)
      group = @project.group
    end

    params.permit(:state).merge(project_ids: @project.id, group_ids: group&.id)
  end
end
