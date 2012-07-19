class Admin::ProjectsController < ApplicationController
  layout "admin"
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def index
    @admin_projects = Project.scoped
    @admin_projects = @admin_projects.search(params[:name]) if params[:name].present?
    @admin_projects = @admin_projects.page(params[:page]).per(20)
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

    @admin_project.update_repository

    redirect_to [:admin, @admin_project], notice: 'Project was successfully updated.'
  end

  def create
    @admin_project = Project.new(params[:project])
    @admin_project.owner = current_user

    if @admin_project.save
      redirect_to [:admin, @admin_project], notice: 'Project was successfully created.'
    else
      render :action => "new"
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

    redirect_to admin_projects_url, notice: 'Project was successfully deleted.'
  end
end
