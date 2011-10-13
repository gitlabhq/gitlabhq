class Admin::ProjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def index
    @admin_projects = Project.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @admin_projects }
    end
  end

  def show
    @admin_project = Project.find_by_code(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @admin_project }
    end
  end

  def new
    @admin_project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @admin_project }
    end
  end

  def edit
    @admin_project = Project.find_by_code(params[:id])
  end

  def create
    @admin_project = Project.new(params[:project])
    @admin_project.owner = current_user

    respond_to do |format|
      if @admin_project.save
        format.html { redirect_to [:admin, @admin_project], notice: 'Project was successfully created.' }
        format.json { render json: @admin_project, status: :created, location: @admin_project }
      else
        format.html { render action: "new" }
        format.json { render json: @admin_project.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @admin_project = Project.find_by_code(params[:id])

    respond_to do |format|
      if @admin_project.update_attributes(params[:project])
        format.html { redirect_to [:admin, @admin_project], notice: 'Project was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @admin_project.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @admin_project = Project.find_by_code(params[:id])
    @admin_project.destroy

    respond_to do |format|
      format.html { redirect_to admin_projects_url }
      format.json { head :ok }
    end
  end
end
