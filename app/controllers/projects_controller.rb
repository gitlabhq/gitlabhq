class ProjectsController < ApplicationController
  before_filter :project, :except => [:index, :new, :create] 

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!, :except => [:index, :new, :create] 
  before_filter :authorize_admin_project!, :only => [:edit, :update, :destroy] 

  def index
    @projects = current_user.projects.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  def show
    @repo = project.repo
    @commit = @repo.commits.first
    @tree = @commit.tree
    @tree = @tree / params[:path] if params[:path]

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: project }
    end
  rescue Grit::NoSuchPathError => ex
    respond_to do |format|
      format.html {render "projects/empty"}
    end
  end

  def tree
    @repo = project.repo
    @branch = if !params[:branch].blank?
                params[:branch]
              elsif !params[:tag].blank?
                params[:tag]
              else
                "master"
              end

    if params[:commit_id]
      @commit = @repo.commits(params[:commit_id]).first
    else 
      @commit = @repo.commits(@branch || "master").first
    end
    @tree = @commit.tree
    @tree = @tree / params[:path] if params[:path]

    respond_to do |format|
      format.html # show.html.erb
      format.js do 
        # temp solution
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
      end
      format.json { render json: project }
    end
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
  end

  def new
    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project }
    end
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
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html { render action: "new" }
        format.js
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  rescue StandardError => ex
    @project.errors.add(:base, "Cant save project. Please try again later")
    respond_to do |format|
      format.html { render action: "new" }
      format.js
      format.json { render json: @project.errors, status: :unprocessable_entity }
    end
  end

  def update
    respond_to do |format|
      if project.update_attributes(params[:project])
        format.html { redirect_to project, notice: 'Project was successfully updated.' }
        format.js 
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.js 
        format.json { render json: project.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :ok }
    end
  end

  def wall
    @notes = @project.common_notes
    @note = Note.new
  end

  protected 

  def project 
    @project ||= Project.find_by_code(params[:id])
  end
end
