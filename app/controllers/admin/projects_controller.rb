class Admin::ProjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def index
    @admin_projects = Project.page(params[:page])
  end

  def show
    @admin_project = Project.find_by_code(params[:id])
  end

  def new
    @admin_project = Project.new
  end

  def edit
    @admin_project = Project.find_by_code(params[:id])
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
