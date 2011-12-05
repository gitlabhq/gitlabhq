require File.join(Rails.root, 'lib', 'graph_commit')

class ProjectsController < ApplicationController
  before_filter :project, :except => [:index, :new, :create]
  layout :determine_layout

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!, :except => [:index, :new, :create]
  before_filter :authorize_admin_project!, :only => [:edit, :update, :destroy]
  before_filter :require_non_empty_project, :only => [:blob, :tree, :graph]
  before_filter :load_refs, :only => :tree # load @branch, @tag & @ref

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
  rescue Gitlabhq::Gitosis::AccessDenied, Gitlabhq::Gitolite::AccessDenied
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
    return render "projects/empty" unless @project.repo_exists? && @project.has_commits?
    limit = (params[:limit] || 20).to_i
    @activities = @project.cached_updates(limit)
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
      format.js { respond_with_notes }
    end
  end

  def graph
    @days_json, @commits_json = GraphCommit.to_graph(project)
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
