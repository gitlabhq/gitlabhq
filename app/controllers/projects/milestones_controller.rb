class Projects::MilestonesController < Projects::ApplicationController
  before_filter :module_enabled
  before_filter :milestone, only: [:edit, :update, :destroy, :show, :sort_issues, :sort_merge_requests]

  # Allow read any milestone
  before_filter :authorize_read_milestone!

  # Allow admin milestone
  before_filter :authorize_admin_milestone!, except: [:index, :show]

  respond_to :html

  def index
    @milestones = case params[:f]
                  when 'all'; @project.milestones.order("state, due_date DESC")
                  when 'closed'; @project.milestones.closed.order("due_date DESC")
                  else @project.milestones.active.order("due_date ASC")
                  end

    @milestones = @milestones.includes(:project)
    @milestones = @milestones.page(params[:page]).per(20)
  end

  def new
    @milestone = @project.milestones.new
    respond_with(@milestone)
  end

  def edit
    respond_with(@milestone)
  end

  def show
    @issues = @milestone.issues
    @users = @milestone.participants.uniq
    @merge_requests = @milestone.merge_requests
  end

  def create
    @milestone = Milestones::CreateService.new(project, current_user, milestone_params).execute

    if @milestone.save
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
          redirect_to [@project, @milestone]
        else
          render :edit
        end
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_milestone, @milestone)

    @milestone.destroy

    respond_to do |format|
      format.html { redirect_to project_milestones_path }
      format.js { render nothing: true }
    end
  end

  def sort_issues
    @issues = @milestone.issues.where(id: params['sortable_issue'])
    @issues.each do |issue|
      issue.position = params['sortable_issue'].index(issue.id.to_s) + 1
      issue.save
    end

    render json: { saved: true }
  end

  def sort_merge_requests
    @merge_requests = @milestone.merge_requests.where(id: params['sortable_merge_request'])
    @merge_requests.each do |merge_request|
      merge_request.position = params['sortable_merge_request'].index(merge_request.id.to_s) + 1
      merge_request.save
    end

    render json: { saved: true }
  end

  protected

  def milestone
    @milestone ||= @project.milestones.find_by!(iid: params[:id])
  end

  def authorize_admin_milestone!
    return render_404 unless can?(current_user, :admin_milestone, @project)
  end

  def module_enabled
    return render_404 unless @project.issues_enabled
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :due_date, :state_event)
  end
end
