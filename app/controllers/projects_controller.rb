class ProjectsController < ApplicationController
  before_filter :project, :except => [:index, :new, :create] 

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!, :except => [:index, :new, :create] 
  before_filter :authorize_admin_project!, :only => [:edit, :update, :destroy] 

  before_filter :require_non_empty_project, :only => [:blob, :tree, :show]

  def index
    @projects = current_user.projects.all
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = Project.new(params[:project])
    @project.owner = current_user

    Project.transaction do 
      @project.save!
      @project.users_projects.create!(:admin => true, :read => true, :write => true, :user => current_user)
    end

    respond_to do |format|
      if @project.valid?
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.js 
      else
        format.html { render action: "new" }
        format.js
      end
    end
  rescue Gitosis::AccessDenied
    render :js => "location.href = '#{errors_gitosis_path}'" and return
  rescue StandardError => ex
    @project.errors.add(:base, "Cant save project. Please try again later")
    respond_to do |format|
      format.html { render action: "new" }
      format.js
    end
  end

  def update
    respond_to do |format|
      if project.update_attributes(params[:project])
        format.html { redirect_to project, :notice => 'Project was successfully updated.' }
        format.js 
      else
        format.html { render action: "edit" }
        format.js 
      end
    end
  end

  def show
    @date = Date.today - 7.days
    @heads = @project.repo.heads
    @commits = @heads.map do |h| 
      @project.repo.log(h.name, nil, :since => @date)
    end.flatten.uniq { |c| c.id }.sort { |x, y| x.committed_date <=> x.committed_date }

    @messages = project.notes.last_week.limit(40).order("created_at DESC")
  end

  #
  # Wall
  #

  def wall
    @notes = @project.common_notes
    @note = Note.new
  end

  #
  # Repository preview
  #

  def tree
    load_refs # load @branch, @tag & @ref

    @repo = project.repo

    if params[:commit_id]
      @commit = @repo.commits(params[:commit_id]).first
    else 
      @commit = @repo.commits(@ref || "master").first
    end

    @tree = @commit.tree
    @tree = @tree / params[:path] if params[:path]

    respond_to do |format|
      format.html # show.html.erb
      format.js do 
        # diasbale cache to allow back button works
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
      end
    end
  rescue
    return render_404
  end

  def blob
    @repo = project.repo
    @commit = project.commit(params[:commit_id])
    @tree = project.tree(@commit, params[:path])

    if @tree.is_a?(Grit::Blob)
      send_data(@tree.data, :type => @tree.mime_type, :disposition => 'inline', :filename => @tree.name)
    else 
      head(404)
    end
  rescue
    return render_404
  end

  def destroy
    project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
    end
  end

  protected 

  def project 
    @project ||= Project.find_by_code(params[:id])
  end
end
