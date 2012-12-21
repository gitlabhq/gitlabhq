require Rails.root.join('lib', 'gitlab', 'graph', 'json_builder')

class ProjectsController < ProjectResourceController
  skip_before_filter :project, only: [:new, :create]

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
    @project = Project.create_by_user(params[:project], current_user)

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
    status = ProjectUpdateContext.new(project, current_user, params).execute

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
        unless @project.empty_repo?
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
    @note = Note.new

    respond_to do |format|
      format.html
    end
  end

  def graph
    respond_to do |format|
      format.html
      format.json do
        graph = Gitlab::Graph::JsonBuilder.new(project)
        render :json => graph.to_json
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, project)

    # Disable the UsersProject update_repository call, otherwise it will be
    # called once for every person removed from the project
    UsersProject.skip_callback(:destroy, :after, :update_repository)
    project.destroy
    UsersProject.set_callback(:destroy, :after, :update_repository)

    respond_to do |format|
      format.html { redirect_to root_path }
    end
  end
end
