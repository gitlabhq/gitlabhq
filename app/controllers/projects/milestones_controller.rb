class Projects::MilestonesController < Projects::ApplicationController
  before_filter :module_enabled
  before_filter :milestone, only: [:edit, :update, :destroy, :show]

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
    @milestone = @project.milestones.new(params[:milestone])
    @milestone.author_id_of_changes = current_user.id

    if @milestone.save
      redirect_to project_milestone_path(@project, @milestone)
    else
      render "new"
    end
  end

  def update
    @milestone.update_attributes(params[:milestone].merge(author_id_of_changes: current_user.id))

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
end
