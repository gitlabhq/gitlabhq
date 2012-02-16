require File.join(Rails.root, 'lib', 'graph_commit')

class ProjectsController < ApplicationController
  before_filter :project, :except => [:index, :new, :create]
  layout :determine_layout

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!, :except => [:index, :new, :create]
  before_filter :authorize_admin_project!, :only => [:edit, :update, :destroy]
  before_filter :require_non_empty_project, :only => [:blob, :tree, :graph]

  def index
    @limit, @offset = (params[:limit] || 16), (params[:offset] || 0)
    @projects = current_user.projects.limit(@limit).offset(@offset)
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
      @project.users_projects.create!(:project_access => UsersProject::MASTER, :user => current_user)

      # when project saved no team member exist so 
      # project repository should be updated after first user add
      @project.update_repository
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
  rescue Gitlabhq::Gitolite::AccessDenied
    render :js => "location.href = '#{errors_githost_path}'" and return
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
        format.html { redirect_to edit_project_path(project), :notice => 'Project was successfully updated.' }
        format.js
      else
        format.html { render action: "edit" }
        format.js
      end
    end
  end

  def show
    return render "projects/empty" unless @project.repo_exists? && @project.has_commits?
    limit = (params[:limit] || 10).to_i
    @activities = @project.activities(limit)
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
    @notes = @project.common_notes.order("created_at DESC")
    @notes = @notes.fresh.limit(20)

    respond_to do |format|
      format.html
      format.js { respond_with_notes }
    end
  end

  def graph
    render_full_content
    @days_json, @commits_json = GraphCommit.to_graph(project)
  end

  def destroy
    # Disable the UsersProject update_repository call, otherwise it will be
    # called once for every person removed from the project
    UsersProject.skip_callback(:destroy, :after, :update_repository)
    project.destroy
    UsersProject.set_callback(:destroy, :after, :update_repository)

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
