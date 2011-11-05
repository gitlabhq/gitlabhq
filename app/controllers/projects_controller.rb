class ProjectsController < ApplicationController
  before_filter :project, :except => [:index, :new, :create]
  layout :determine_layout

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!, :except => [:index, :new, :create]
  before_filter :authorize_admin_project!, :only => [:edit, :update, :destroy]

  before_filter :require_non_empty_project, :only => [:blob, :tree]

  def index
    source = current_user.projects
    source = source.tagged_with(params[:tag]) unless params[:tag].blank?
    @projects = source.all
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
    return render "projects/empty" unless @project.repo_exists?
    @date = case params[:view]
            when "week" then Date.today - 7.days
            when "day" then Date.today
            else nil
            end

    if @date
      @date = @date.at_beginning_of_day

      @commits = @project.commits_since(@date)
      @messages = project.notes.since(@date).order("created_at DESC")
    else
      @commits = @project.fresh_commits
      @messages = project.notes.fresh.limit(10)
    end
  end

  #
  # Wall
  #

  def wall
    @note = Note.new
    @notes = @project.common_notes.order("created_at DESC")
    @notes = @notes.fresh.limit(20)

    respond_to do |format| 
      format.html
      format.js do 
        @notes = @notes.where("id > ?", params[:last_id]) if params[:last_id]
        @notes = @notes.where("id < ?", params[:first_id]) if params[:first_id]
      end
    end
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

  def determine_layout
    if @project && !@project.new_record?
      "project"
    else
      "application"
    end
  end
end
