require Rails.root.join('lib', 'gitlab', 'graph', 'json_builder')

class ProjectsController < ProjectResourceController
  skip_before_filter :project, only: [:new, :create]
  skip_before_filter :repository, only: [:new, :create]

  # Authorize
  before_filter :authorize_read_project!, except: [:index, :new, :create]
  before_filter :authorize_admin_project!, only: [:edit, :update, :destroy]
  before_filter :require_non_empty_project, only: [:blob, :tree, :graph]

  layout 'application', only: [:new, :create]

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = ::Projects::CreateContext.new(current_user, params[:project]).execute

    respond_to do |format|
      flash[:notice] = 'Project was successfully created.' if @project.saved?
      format.html do
        if @project.saved?
          redirect_to @project
        else
          render action: "new"
        end
      end
      format.js
    end
  end

  def update
    status = ::Projects::UpdateContext.new(project, current_user, params).execute

    respond_to do |format|
      if status
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to edit_project_path(project), notice: 'Project was successfully updated.' }
        format.js
      else
        format.html { render action: "edit" }
        format.js
      end
    end

  rescue Project::TransferError => ex
    @error = ex
    render :update_failed
  end

  def show
    limit = (params[:limit] || 20).to_i
    @events = @project.events.recent.limit(limit).offset(params[:offset] || 0)

    respond_to do |format|
      format.html do
        if @project.repository && !@project.repository.empty?
          @last_push = current_user.recent_push(@project.id)
          render :show
        else
          render "projects/empty"
        end
      end
      format.js
    end
  end

  def files
    @notes = @project.notes.where("attachment != 'NULL'").order("created_at DESC").limit(100)
  end

  #
  # Wall
  #

  def wall
    return render_404 unless @project.wall_enabled

    @target_type = :wall
    @target_id = nil
    @note = @project.notes.new

    respond_to do |format|
      format.html
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, project)

    # Delete team first in order to prevent multiple gitolite calls
    project.team.truncate

    project.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
    end
  end
end
