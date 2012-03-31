class Admin::ProjectsController < ApplicationController
  layout "admin"
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def index
    @admin_projects = Project.page(params[:page])
  end

  def show
    @admin_project = Project.find_by_code(params[:id])

    @users = if @admin_project.users.empty?
               User
             else
               User.not_in_project(@admin_project)
             end.all
  end

  def new
    @admin_project = Project.new
  end

  def edit
    @admin_project = Project.find_by_code(params[:id])
  end

  def team_update
    @admin_project = Project.find_by_code(params[:id])

    UsersProject.bulk_import(
      @admin_project, 
      params[:user_ids],
      params[:project_access]
    )

    redirect_to [:admin, @admin_project], notice: 'Project was successfully updated.'
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
    @admin_project = Project.find_by_code(params[:id])

    owner_id = params[:project].delete(:owner_id)

    if owner_id 
      @admin_project.owner = User.find(owner_id)
    end

    if @admin_project.update_attributes(params[:project])
      redirect_to [:admin, @admin_project], notice: 'Project was successfully updated.'
    else
      render :action => "edit"
    end
  end

  def destroy
    @admin_project = Project.find_by_code(params[:id])
    @admin_project.destroy

    redirect_to admin_projects_url
  end
end
